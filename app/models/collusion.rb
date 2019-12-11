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

# class Collusion < PostCustomField
#   validates        :user,      presence: true
#   validates        :post,      presence: true
#   validates        :changeset, presence: true
#   validates        :version,   numericality: { greater_than: 0 }
#   after_initialize :set_name
#
#   default_scope { where(name: :collusion) }
#
#   def self.collusion_accessor(*fields)
#     Array(fields).each do |field|
#       define_method field,        ->      { collusion[field.to_s] }
#       define_method :"#{field}=", ->(val) { collusion[field.to_s] = val }
#     end
#   end
#   collusion_accessor :user_id, :version
#
#   def self.spawn(post:, user:, changeset:)
#     create(
#       user:      user,
#       post:      post,
#       version:   post.latest_collusion.version + 1,
#       changeset: changeset,
#       value:     changeset.apply_to(post.latest_collusion)
#     ) if post.can_collude?
#   end
#
#   def changeset
#     @changeset ||= Changeset.new(collusion['changeset'].to_h)
#   end
#
#   def changeset=(value)
#     collusion['changeset'] = value
#   end
#
#
#   def user
#     @user ||= User.find_by(id: user_id)
#   end
#
#   def user=(u)
#     self.user_id = u.id
#   end
#
#   def set_name
#     self.name ||= :collusion
#   end
# end
