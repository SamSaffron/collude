# frozen_string_literal: true

class Collusion < ActiveRecord::Base
  validates        :user,      presence: true
  validates        :post,      presence: true
  validates        :changeset, presence: true
  validates        :version,   numericality: { greater_than: 0 }

  belongs_to :post
  belongs_to :user

  def self.spawn(post:, user:, changeset:)
    return unless post.can_collude?

    create(
      user: user,
      post: post,
      version: post.latest_collusion.version + 1,
      changeset: changeset,
      value: changeset.apply_to(post.latest_collusion)
    )
  end

  def self.latest_collusion(post_id)
    Collusion
      .where(post_id: post_id)
      .order(:version)
      .last
  end

  def changeset
    @changeset ||= Changeset.new(super.to_h)
  end

  def changeset=(val)
    @changeset = super(val)
  end
end
