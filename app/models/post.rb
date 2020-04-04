# frozen_string_literal: true

class Post
  def can_collude?
    SiteSetting.collude_enabled &&
      is_first_post? &&
      topic&.archetype == Archetype.default &&
      custom_fields['collude']
  end

  def latest_collusion
    return unless can_collude?

    Collusion.latest_collusion(id) || setup_initial_collusion!
  end

  private

  def setup_initial_collusion!
    return unless can_collude?

    Collusion.create!(
      user: user,
      value: raw,
      version: 1,
      changeset: initial_changeset,
      post: self
    )
  end

  def initial_changeset
    Changeset.new(
      length_before: 0,
      length_after: raw.to_s.length,
      changes: Array([raw, user_id].join("ØØ"))
    )
  end
end
