# frozen_string_literal: true

class Collusion
  def self.create(user:, post:, version:, changeset:, value:)
    value = {
      user_id: user.id,
      changeset: changeset,
      value: value,
      post_id: post.id
    }
    query = {
      plugin_name: "collusion:#{post.id}",
      key: version,
      value: value.to_json,
      type_name: 'JSON'
    }

    store = PluginStoreRow.create!(query)
    Collusion.new(store)
  end

  def self.spawn(post:, user:, changeset:)
    return unless post.can_collude?

    opts = {
      user: user,
      post: post,
      version: post.latest_collusion.version + 1,
      changeset: changeset,
      value: changeset.apply_to(post.latest_collusion)
    }

    create(opts)
  end

  def self.latest_collusion(post_id)
    store = PluginStoreRow
            .where(plugin_name: "collusion:#{post_id}")
            .order(:key)
            .last

    return unless store

    Collusion.new(store)
  end

  def initialize(store)
    @store = store
    @value = JSON.parse(store.value)
  end

  def changeset
    @changeset ||= Changeset.new(@value['changeset'].to_h)
  end

  def version
    @store.key.to_i
  end

  def value
    @value['value']
  end

  def user_id
    @value['user_id']
  end

  def post_id
    @value['post_id']
  end
end
