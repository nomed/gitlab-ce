# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Project < Base
      include Events::Project

      attribute :name
      attribute :add_name_uuid
      attribute :description
      attribute :standalone

      attribute :group do
        Group.fabricate!
      end

      attribute :path_with_namespace do
        "#{group.sandbox.path}/#{group.path}/#{name}" if group
      end

      attribute :repository_ssh_location do
        Page::Project::Show.perform do |page|
          page.repository_clone_ssh_location
        end
      end

      attribute :repository_http_location do
        Page::Project::Show.perform do |page|
          page.repository_clone_http_location
        end
      end

      def initialize
        @name = "#{@name}-#{SecureRandom.hex(8)}" if @add_name_uuid
        @description = 'My awesome project'
        @standalone = false
      end

      def fabricate!
        unless @standalone
          group.visit!
          Page::Group::Show.perform(&:go_to_new_project)
        end

        Page::Project::New.perform do |page|
          page.choose_test_namespace
          page.choose_name(@name)
          page.add_description(@description)
          page.set_visibility('Public')
          page.create_new_project
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def api_get_path
        "/projects/#{CGI.escape(path_with_namespace)}"
      end

      def api_post_path
        '/projects'
      end

      def api_post_body
        if @standalone
          {
            name: name,
            description: description,
            visibility: 'public'
          }
        else
          {
            namespace_id: group.id,
            path: name,
            name: name,
            description: description,
            visibility: 'public'
          }
        end
      end

      private

      def transform_api_resource(api_resource)
        api_resource[:repository_ssh_location] =
          Git::Location.new(api_resource[:ssh_url_to_repo])
        api_resource[:repository_http_location] =
          Git::Location.new(api_resource[:http_url_to_repo])
        api_resource
      end
    end
  end
end
