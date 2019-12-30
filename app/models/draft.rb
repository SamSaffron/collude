# frozen_string_literal: true

require_dependency 'draft'
class Draft
  class << self
    alias orig_set set

    def set(user, _key, sequence, data, _owner = nil)
      data = JSON.parse(data)
      # sequence = orig_set(user, key, sequence, data.to_json, owner)

      if data['action'] == 'colludeOnTopic'
        post_id = data['postId']
        hash = data['changesets']['submitted']
        changeset = Changeset.new(
          length_before: hash['length_before'].to_i,
          length_after: hash['length_after'].to_i,
          changes: hash['changes']
        )
        post = Post.find(post_id)
        collusion = Collusion.spawn(
          post: post,
          user: user,
          changeset: changeset
        )
        serializer = CollusionSerializer.new(collusion, scope: user).as_json

        MessageBus.publish("/collusions/#{post.topic_id}", serializer)

        scheduler = Collude::Scheduler.new(post, user)

        if data['colludeDone']
          scheduler.revise!
        else
          scheduler.schedule!
        end
      end

      sequence
    end
  end
end
