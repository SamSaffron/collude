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
      changes = {
        raw: @post.latest_collusion.value
      }

      revisor.revise!(@user, changes, opts)
    end
  end
end
