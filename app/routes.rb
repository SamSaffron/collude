# frozen_string_literal: true

Discourse::Application.routes.append do
  put 'posts/:id/collude' => 'posts#toggle_collusion', constraints: StaffConstraint.new
  get 'posts/:id/latest_collusion' => 'posts#latest_collusion'
end
