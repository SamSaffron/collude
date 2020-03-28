# frozen_string_literal: true

require_dependency 'posts_controller'

class PostsController
  before_action :ensure_staff, only: [:toggle_collusion]

  def toggle_collusion
    post = find_post_from_params

    post.custom_fields['collude'] = params[:collude]
    post.save_custom_fields
    post.publish_change_to_clients!(:revised)

    render body: nil
  end

  def latest_collusion
    post = find_post_from_params

    guardian.ensure_can_collude!(post)

    Collude::Scheduler.new(post, current_user).set_debounce_value

    render json: CollusionSerializer.new(post.latest_collusion).as_json
  end
end
