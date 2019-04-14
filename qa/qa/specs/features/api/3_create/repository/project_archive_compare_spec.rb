# frozen_string_literal: true

require 'securerandom'
require 'digest'

module QA
  context 'Create' do
    describe 'Compare archives of different user projects with the same name and check they\'re different' do
      before(:all) do
        @project_name = "project-archive-download-#{SecureRandom.hex(8)}"
        @archive_types = %w(tar.gz tar.bz2 tar zip)
        @users = { user1: {}, user2: {} }

        @users.each do |_, user_info|
          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          user_info[:user] = Resource::User.fabricate_or_use
          user_info[:api_client] = Runtime::API::Client.new(:gitlab, user: user_info[:user])
          user_info[:api_client].personal_access_token
          user_info[:project] = create_project(user_info[:user], user_info[:api_client], @project_name)
        end
      end

      it 'download archives of each user project then check they are different' do
        archive_checksums = {}

        @users.each do |user_key, user_info|
          archive_checksums[user_key] = {}

          @archive_types.each do |type|
            archive_path = download_project_archive(user_info[:api_client], user_info[:project], type).path
            archive_checksums[user_key][type] = Digest::MD5.hexdigest(File.read(archive_path))
          end
        end

        QA::Runtime::Logger.debug("Archive checksums are #{archive_checksums}")

        expect(archive_checksums[:user1]).not_to include(archive_checksums[:user2])
      end

      def create_project(user, api_client, project_name)
        project = Resource::Project.fabricate! do |project|
          project.name = project_name
          project.path_with_namespace = "#{user.name}/#{project_name}"
          project.user = user
          project.api_client = api_client
          project.standalone = true
          project.add_name_uuid = false
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
          push.user = user
        end

        project
      end

      def download_project_archive(api_client, project, type = 'tar.gz')
        sanitized_project_path = CGI.escape(project.path_with_namespace)

        get_project_archive_zip = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/archive.#{type}")
        project_archive_download = download_raw_file(get_project_archive_zip.url)
        expect(project_archive_download.code).to eq(200)

        project_archive_download.file
      end

      def download_raw_file(url)
        RestClient::Request.execute(
          method: :get,
          url: url,
          verify_ssl: false,
          raw_response: true)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end
    end
  end
end
