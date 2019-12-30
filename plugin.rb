# name: collude
# about: Collaborative document editing for Discourse
# version: 0.0.2
# authors: James Kiesel (gdpelican)
# url: https://github.com/gdpelican/collude

enabled_site_setting :collude_enabled

%i[common desktop mobile].each do |type|
  register_asset "stylesheets/collude/#{type}.scss", type
end

def collude_require(path)
  require_relative File.expand_path("../app/#{path}", __FILE__)
end

after_initialize do
  collude_require 'controllers/posts_controller'
  collude_require 'lib/guardian/post_guardian'
  collude_require 'models/changeset'
  collude_require 'models/collusion'
  collude_require 'models/post'
  collude_require 'models/draft'
  # collude_require 'jobs/collude'
  collude_require 'serializers/changeset_serializer'
  collude_require 'serializers/collusion_serializer'
  collude_require 'services/applier'
  collude_require 'services/merger'
  collude_require 'services/scheduler'
  collude_require 'routes'

  register_post_custom_field_type 'collude', :boolean
  add_to_serializer :post, :collude do
    object.can_collude?
  end

  register_svg_icon('far-handshake')
end
