# frozen_string_literal: true

require_dependency 'guardian'

class Guardian
  module CanCollude
    def can_edit_post?(post)
      super(post) || can_collude?(post)
    end

    def can_collude?(post)
      post.can_collude? &&
        @user.has_trust_level?(TrustLevel[SiteSetting.collude_min_trust_level])
    end
  end

  prepend CanCollude
end
