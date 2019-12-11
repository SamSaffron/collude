# frozen_string_literal: true

class ChangesetSerializer < ActiveModel::Serializer
  root false
  attributes :length_before, :length_after, :changes

  def length_before
    object.length_before
  end

  def length_after
    object.length_after
  end

  def changes
    object.changes
  end
end
