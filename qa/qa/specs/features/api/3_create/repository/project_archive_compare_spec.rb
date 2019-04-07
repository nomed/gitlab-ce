# frozen_string_literal: true

require 'securerandom'
require 'digest'

module QA
  context 'Create' do
    describe 'Compare archives of different user projects with the same name and check they\'re different', order: :defined do
      before(:all) do
        @api_clients = { user1: Runtime::API::Client.new(:gitlab, is_new_user: true), user2: Runtime::API::Client.new(:gitlab, is_new_user: true) }
        @project_name = "project-archive-download-#{SecureRandom.hex(8)}"
        @archive_types = %w(tar.gz tar.bz2 tar zip)
        @archive_checksums = { user1: {}, user2: {} }
      end

      it 'user1 creates, downloads and gets checksums of project archives' do
        create_project(@api_clients[:user1], @project_name)

        @archive_types.each do |type|
          archive_path = download_project_archive(@api_clients[:user1], @project_name, type).path
          @archive_checksums[:user1][type] = file_checksum(archive_path)
        end
      end

      it 'user2 creates, downloads and gets checksums of project archives' do
        create_project(@api_clients[:user2], @project_name)

        @archive_types.each do |type|
          archive_path = download_project_archive(@api_clients[:user2], @project_name, type).path
          @archive_checksums[:user2][type] = file_checksum(archive_path)
        end
      end

      it 'compare the archives and check they are different' do
        expect(@archive_checksums[:user1]).not_to include(@archive_checksums[:user2])
      end

      def create_project(api_client, project_name)
        api_client.personal_access_token
        sanitized_project_path = CGI.escape("#{api_client.user.username}/#{project_name}")

        create_project_request = Runtime::API::Request.new(api_client, '/projects')
        post create_project_request.url, path: project_name, name: project_name
        expect_status(201)
        expect(json_body).to match(
          a_hash_including(name: project_name, path: project_name)
        )

        create_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/README.md")
        post create_file_request.url, branch: 'master', content: 'Hello world', commit_message: 'Add README.md'
        expect_status(201)
        expect(json_body).to match(
          a_hash_including(branch: 'master', file_path: 'README.md')
        )
      end

      def download_project_archive(api_client, project_name, type = 'tar.gz')
        sanitized_project_path = CGI.escape("#{api_client.user.username}/#{project_name}")

        get_project_archive_zip = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/archive.#{type}")
        project_archive_download = download_raw_file get_project_archive_zip.url
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

      def file_checksum(filepath)
        Digest::MD5.hexdigest(File.read(filepath))
      end
    end
  end
end
