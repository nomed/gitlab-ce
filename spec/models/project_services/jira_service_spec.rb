# frozen_string_literal: true

require 'spec_helper'

describe JiraService do
  include Gitlab::Routing
  include AssetsHelpers

  let(:url) { 'http://jira.example.com' }
  let(:api_url) { 'http://api-jira.example.com' }
  let(:username) { 'jira-username' }
  let(:password) { 'jira-password' }
  let(:transition_id) { 'test27' }

  describe '#options' do
    let(:service) do
      described_class.new(
        project: build_stubbed(:project),
        active: true,
        username: 'username',
        password: 'test',
        jira_issue_transition_id: 24,
        url: 'http://jira.test.com/path/'
      )
    end

    it 'sets the URL properly' do
      # jira-ruby gem parses the URI and handles trailing slashes
      # fine: https://github.com/sumoheavy/jira-ruby/blob/v1.4.1/lib/jira/http_client.rb#L59
      expect(service.options[:site]).to eq('http://jira.test.com/')
    end

    it 'leaves out trailing slashes in context' do
      expect(service.options[:context_path]).to eq('/path')
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does not allow # on the code' do
      expect(described_class.reference_pattern.match('#123')).to be_nil
      expect(described_class.reference_pattern.match('1#23#12')).to be_nil
    end
  end

  # we need to make sure we are able to read both from properties and jira_tracker_data table
  # TODO: change this as part of #63084
  describe 'reading fields' do
    shared_examples 'read data' do
      it 'reads data correctly' do
        expect(jira_service.url).to eq(url)
        expect(jira_service.api_url).to eq(api_url)
        expect(jira_service.username).to eq(username)
        expect(jira_service.password).to eq(password)
        expect(jira_service.jira_issue_transition_id).to eq(transition_id)
      end
    end

    context 'when data are stored in properties' do
      let(:jira_service) do
        properties = {
          url: url, api_url: api_url, username: username, password: password, jira_issue_transition_id: transition_id
        }
        create(:jira_service, properties: properties, active: false)
      end

      include_examples 'read data'
    end

    context 'when data are stored in jira_tracker_data' do
      let(:jira_service) do
        create(:jira_service, properties: nil).tap do |service|
          create(:jira_tracker_data, service: service, url: url, api_url: api_url,
                 username: username, password: password, jira_issue_transition_id: transition_id)
        end
      end

      include_examples 'read data'
    end
  end

  describe '#create' do
    let(:params) do
      {
        project: create(:project), title: 'custom title',
        url: url, api_url: api_url,
        username: username, password: password,
        jira_issue_transition_id: transition_id
      }
    end

    subject { described_class.create(params) }

    it 'does not store data into properties' do
      expect(subject.properties).to be_empty
    end

    it 'sets title  correctly' do
      service = subject

      expect(service.title).to eq('custom title')
    end

    it 'sets data correctly' do
      service = subject

      expect(service.url).to eq(url)
      expect(service.api_url).to eq(api_url)
      expect(service.username).to eq(username)
      expect(service.password).to eq(password)
      expect(service.jira_issue_transition_id).to eq(transition_id)
    end
  end

  describe '#update' do
    shared_examples 'saving data' do
      before do
        jira_service
        jira_service.update(username: 'new_username')
      end

      it 'leaves properties field emtpy' do
        expect(jira_service.reload.properties).to be_empty
      end

      it 'stores updated data in jira_tracker_data table' do
        data = jira_service.jira_tracker_data.reload

        expect(data.url).to eq(url)
        expect(data.api_url).to eq(api_url)
        expect(data.username).to eq('new_username')
        expect(data.password).to eq(password)
        expect(data.jira_issue_transition_id).to eq(transition_id)
      end
    end

    shared_examples 'stored password invalidation' do
      context 'when a password was previously set' do
        context 'when only web url present' do
          let(:data_params) do
            {
              url: url, api_url: nil,
              username: username, password: password,
              jira_issue_transition_id: transition_id
            }
          end

          it 'resets password if url changed' do
            jira_service.url = 'http://jira_edited.example.com'
            jira_service.save

            expect(jira_service.reload.password).to be_nil
          end

          it 'resets password if url not changed but api url added' do
            jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
            jira_service.save

            expect(jira_service.password).to be_nil
          end

          it 'does not reset password if new url is set together with password, even if it\'s the same password' do
            jira_service.url = 'http://jira_edited.example.com'
            jira_service.password = password
            jira_service.save

            expect(jira_service.password).to eq(password)
            expect(jira_service.url).to eq('http://jira_edited.example.com')
          end

          it 'resets password if url changed, even if setter called multiple times' do
            jira_service.url = 'http://jira1.example.com/rest/api/2'
            jira_service.url = 'http://jira1.example.com/rest/api/2'
            jira_service.save

            expect(jira_service.password).to be_nil
          end

          it 'does not reset password if username changed' do
            jira_service.username = 'some_name'
            jira_service.save

            expect(jira_service.reload.password).to eq(password)
          end
        end

        context 'when both web and api url present' do
          let(:data_params) do
            {
              url: url, api_url: 'http://jira.example.com/rest/api/2',
              username: username, password: password,
              jira_issue_transition_id: transition_id
            }
          end

          it 'resets password if api url changed' do
            jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
            jira_service.save

            expect(jira_service.password).to be_nil
          end

          it 'does not reset password if url changed' do
            jira_service.url = 'http://jira_edited.example.com'
            jira_service.save

            expect(jira_service.password).to eq(password)
          end

          it 'resets password if api url set to empty' do
            jira_service.update(api_url: '')

            expect(jira_service.reload.password).to be_nil
          end
        end
      end

      context 'when no password was previously set' do
        let(:data_params) do
          {
            url: url, username: username
          }
        end

        it 'saves password if new url is set together with password' do
          jira_service.url = 'http://jira_edited.example.com/rest/api/2'
          jira_service.password = 'password'
          jira_service.save
          expect(jira_service.reload.password).to eq('password')
          expect(jira_service.reload.url).to eq('http://jira_edited.example.com/rest/api/2')
        end
      end
    end

    # TODO: this will be removed as part of #63084
    context 'when data are stored in properties' do
      let(:properties) do
        {
          url: url, api_url: api_url,
          username: username, password: password,
          jira_issue_transition_id: transition_id
        }
      end

      context 'basic saving' do
        let(:jira_service) do
          build(:jira_service, properties: properties).tap { |service| service.save(validate: false) }
        end

        include_examples 'saving data'
      end

      describe 'Stored password invalidation' do
        let(:params) { {} }
        let(:jira_service) do
          create(:jira_service, properties: data_params, active: false)
        end

        include_examples 'stored password invalidation'
      end
    end

    context 'when data are stored in data table' do
      context 'basic update' do
        let(:jira_service) do
          create(:jira_service, properties: nil).tap do |service|
            create(:jira_tracker_data, service: service,
                   url: url, api_url: api_url, username: username, password: password,
                   jira_issue_transition_id: transition_id)
          end
        end

        include_examples 'saving data'
      end

      describe 'Stored password invalidation' do
        let(:params) { {} }
        let(:jira_service) do
          create(:jira_service, properties: {}, active: false).tap do |service|
            create(:jira_tracker_data, data_params.merge(service: service))
          end
        end

        include_examples 'stored password invalidation'
      end
    end
  end

  describe '#close_issue' do
    let(:custom_base_url) { 'http://custom_url' }
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    shared_examples 'close_issue' do
      before do
        @jira_service = described_class.new
        allow(@jira_service).to receive_messages(
          project_id: project.id,
          project: project,
          service_hook: true,
          url: 'http://jira.example.com',
          username: 'gitlab_jira_username',
          password: 'gitlab_jira_password',
          jira_issue_transition_id: '999'
        )

        # These stubs are needed to test JiraService#close_issue.
        # We close the issue then do another request to API to check if it got closed.
        # Here is stubbed the API return with a closed and an opened issues.
        open_issue   = JIRA::Resource::Issue.new(@jira_service.client, attrs: { 'id' => 'JIRA-123' })
        closed_issue = open_issue.dup
        allow(open_issue).to receive(:resolution).and_return(false)
        allow(closed_issue).to receive(:resolution).and_return(true)
        allow(JIRA::Resource::Issue).to receive(:find).and_return(open_issue, closed_issue)

        allow_any_instance_of(JIRA::Resource::Issue).to receive(:key).and_return('JIRA-123')
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])

        @jira_service.save

        project_issues_url = 'http://jira.example.com/rest/api/2/issue/JIRA-123'
        @transitions_url   = 'http://jira.example.com/rest/api/2/issue/JIRA-123/transitions'
        @comment_url       = 'http://jira.example.com/rest/api/2/issue/JIRA-123/comment'
        @remote_link_url   = 'http://jira.example.com/rest/api/2/issue/JIRA-123/remotelink'

        WebMock.stub_request(:get, project_issues_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
        WebMock.stub_request(:post, @transitions_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
        WebMock.stub_request(:post, @comment_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
        WebMock.stub_request(:post, @remote_link_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
      end

      it 'calls JIRA API' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: /Issue solved with/
        ).once
      end

      it 'does not fail if remote_link.all on issue returns nil' do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return(nil)

        expect { @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project)) }
            .not_to raise_error(NoMethodError)
      end

      # Check https://developer.atlassian.com/jiradev/jira-platform/guides/other/guide-jira-remote-issue-links/fields-in-remote-issue-links
      # for more information
      it 'creates Remote Link reference in JIRA for comment' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        favicon_path = "http://localhost/assets/#{find_asset('favicon.png').digest_path}"

        # Creates comment
        expect(WebMock).to have_requested(:post, @comment_url)
        # Creates Remote Link in JIRA issue fields
        expect(WebMock).to have_requested(:post, @remote_link_url).with(
          body: hash_including(
            GlobalID: 'GitLab',
            relationship: 'mentioned on',
            object: {
              url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/#{commit_id}",
              title: "Solved by commit #{commit_id}.",
              icon: { title: 'GitLab', url16x16: favicon_path },
              status: { resolved: true }
            }
          )
        ).once
      end

      it 'does not send comment or remote links to issues already closed' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:resolution).and_return(true)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).not_to have_requested(:post, @comment_url)
        expect(WebMock).not_to have_requested(:post, @remote_link_url)
      end

      it 'does not send comment or remote links to issues with unknown resolution' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:respond_to?).with(:resolution).and_return(false)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).not_to have_requested(:post, @comment_url)
        expect(WebMock).not_to have_requested(:post, @remote_link_url)
      end

      it 'references the GitLab commit' do
        stub_config_setting(base_url: custom_base_url)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: %r{#{custom_base_url}/#{project.full_path}/commit/#{commit_id}}
        ).once
      end

      it 'references the GitLab commit' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        allow(described_class).to receive(:default_url_options) do
          { script_name: '/gitlab' }
        end

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: %r{#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/#{commit_id}}
        ).once
      end

      it 'logs exception when transition id is not valid' do
        allow(@jira_service).to receive(:log_error)
        WebMock.stub_request(:post, @transitions_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password)).and_raise("Bad Request")

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(@jira_service).to have_received(:log_error).with("Issue transition failed", error: "Bad Request", client_url: "http://jira.example.com")
      end

      it 'calls the api with jira_issue_transition_id' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @transitions_url).with(
          body: /999/
        ).once
      end

      context 'when have multiple transition ids' do
        it 'calls the api with transition ids separated by comma' do
          allow(@jira_service).to receive_messages(jira_issue_transition_id: '1,2,3')

          @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, @transitions_url).with(
              body: /#{transition_id}/
            ).once
          end
        end

        it 'calls the api with transition ids separated by semicolon' do
          allow(@jira_service).to receive_messages(jira_issue_transition_id: '1;2;3')

          @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, @transitions_url).with(
              body: /#{transition_id}/
            ).once
          end
        end
      end
    end

    context 'when resource is a merge request' do
      let(:resource) { create(:merge_request) }
      let(:commit_id) { resource.diff_head_sha }

      it_behaves_like 'close_issue'
    end

    context 'when resource is a commit' do
      let(:resource) { project.commit('master') }
      let(:commit_id) { resource.id }

      it_behaves_like 'close_issue'
    end
  end

  describe '#test_settings' do
    let(:jira_service) do
      described_class.new(
        project: create(:project),
        url: 'http://jira.example.com',
        username: 'jira_username',
        password: 'jira_password'
      )
    end

    def test_settings(api_url = nil)
      api_url ||= 'jira.example.com'
      test_url = "http://#{api_url}/rest/api/2/serverInfo"

      WebMock.stub_request(:get, test_url).with(basic_auth: %w(jira_username jira_password)).to_return(body: { url: 'http://url' }.to_json )

      jira_service.test(nil)
    end

    context 'when the test succeeds' do
      it 'tries to get JIRA project with URL when API URL not set' do
        test_settings('jira.example.com')
      end

      it 'returns correct result' do
        expect(test_settings).to eq( { success: true, result: { 'url' => 'http://url' } })
      end

      it 'tries to get JIRA project with API URL if set' do
        jira_service.update(api_url: 'http://jira.api.com')
        test_settings('jira.api.com')
      end
    end

    context 'when the test fails' do
      it 'returns result with the error' do
        test_url = 'http://jira.example.com/rest/api/2/serverInfo'
        WebMock.stub_request(:get, test_url).with(basic_auth: %w(jira_username jira_password))
          .to_raise(JIRA::HTTPError.new(double(message: 'Some specific failure.')))

        expect(jira_service.test(nil)).to eq( { success: false, result: 'Some specific failure.' })
      end
    end
  end

  describe 'additional cookies' do
    let(:project) { create(:project) }

    context 'provides additional cookies to allow basic auth with oracle webgate' do
      before do
        @service = project.create_jira_service(
          active: true, properties: { url: 'http://jira.com' })
      end

      after do
        @service.destroy!
      end

      it 'is initialized' do
        expect(@service.options[:use_cookies]).to eq(true)
        expect(@service.options[:additional_cookies]).to eq(['OBBasicAuth=fromDialog'])
      end
    end
  end

  describe 'favicon urls', :request_store do
    it 'includes the standard favicon' do
      props = described_class.new.send(:build_remote_link_props, url: 'http://example.com', title: 'title')
      expect(props[:object][:icon][:url16x16]).to match %r{^http://localhost/assets/favicon(?:-\h+).png$}
    end

    it 'includes returns the custom favicon' do
      create :appearance, favicon: fixture_file_upload('spec/fixtures/dk.png')

      props = described_class.new.send(:build_remote_link_props, url: 'http://example.com', title: 'title')
      expect(props[:object][:icon][:url16x16]).to match %r{^http://localhost/uploads/-/system/appearance/favicon/\d+/dk.png$}
    end
  end
end
