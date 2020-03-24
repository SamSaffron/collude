# frozen_string_literal: true

module Collude
  class Scheduler
    def initialize(post, user)
      @post = post
      @user = user
    end

    def redis
      Discourse.redis.without_namespace
    end

    def redis_key
      "collude_#{@post.id}"
    end

    def mutex_key
      "#{redis_key}_mutex"
    end

    def can_schedule?
      redis.get(redis_key).blank?
    end

    def schedule!
      if can_schedule?
        debounce_time = SiteSetting.collude_server_debounce

        DistributedMutex.synchronize(mutex_key, validity: debounce_time) do
          revise!

          redis.setex(redis_key, debounce_time, 't')
        end
      end
    end

    def revise!
      revisor = PostRevisor.new(@post)

      opts = {
        bypass_rate_limiter: true,
        bypass_bump: true,
        skip_validations: true,
        skip_staff_log: true
      }

      # let PostRevisor handle revision if false
      if !create_new_version?
        opts[:skip_revision] = true
      end

      changes = {
        raw: @post.latest_collusion.value
      }

      revisor.revise!(@user, changes, opts)
    end

    def create_new_version?
      last_version_at = @post.last_version_at || Time.now
      (Time.now - last_version_at) > SiteSetting.editing_grace_period.to_i
    end
  end
end
