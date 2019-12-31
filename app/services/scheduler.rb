# frozen_string_literal: true

module Collude
  class Scheduler
    def initialize(post, user)
      @post = post
      @user = user
    end

    def schedule!
      debounce_time = SiteSetting.collude_server_debounce

      DistributedMutex.synchronize("collude_#{@post.id}", validity: debounce_time) do
        revise!
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
