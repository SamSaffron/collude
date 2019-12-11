# frozen_string_literal: true

class CollusionSerializer < ActiveModel::Serializer
  attributes :version, :user_id, :post_id, :value, :changeset, :actor_id
  has_one :changeset, serializer: ChangesetSerializer

  def actor_id
    scope&.id
  end

  def version
    object.version
  end

  def user_id
    object.user_id
  end

  def post_id
    object.post_id
  end

  def value
    object.value
  end

  def changeset
    object.changeset
  end
end
