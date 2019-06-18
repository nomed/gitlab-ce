# frozen_string_literal: true

require 'spec_helper'

describe JiraTrackerData do
  let(:service) { create(:jira_service, active: false, properties: {}) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'Validations' do
    subject do
      described_class.new(
        service: service,
        url: 'http://jira.example.com',
        api_url: 'http://api-jira.example.com',
        username: 'jira_username',
        password: 'jira_password'
      )
    end

    context 'jira_issue_transition_id' do
      it { is_expected.to allow_value(nil).for(:jira_issue_transition_id) }
      it { is_expected.to allow_value('1,2,3').for(:jira_issue_transition_id) }
      it { is_expected.to allow_value('1;2;3').for(:jira_issue_transition_id) }
      it { is_expected.not_to allow_value('a,b,cd').for(:jira_issue_transition_id) }
    end

    context 'url validations' do
      context 'when service is inactive' do
        it { is_expected.not_to validate_presence_of(:url) }
        it { is_expected.not_to validate_presence_of(:username) }
        it { is_expected.not_to validate_presence_of(:password) }
      end

      context 'when service is active' do
        before do
          service.update(active: true)
        end

        it_behaves_like 'issue tracker service URL attribute', :url

        it { is_expected.to validate_presence_of(:url) }
        it { is_expected.to validate_presence_of(:username) }
        it { is_expected.to validate_presence_of(:password) }

        context 'validating urls' do
          it 'is valid when all fields have required values' do
            expect(subject).to be_valid
          end

          it 'is not valid when url is not a valid url' do
            subject.url = 'not valid'

            expect(subject).not_to be_valid
          end

          it 'is not valid when api url is not a valid url' do
            subject.api_url = 'not valid'

            expect(subject).not_to be_valid
          end

          it 'is not valid when username is missing' do
            subject.username = nil

            expect(subject).not_to be_valid
          end

          it 'is not valid when password is missing' do
            subject.password = nil

            expect(subject).not_to be_valid
          end

          it 'is valid when api url is a valid url' do
            subject.api_url = 'http://jira.test.com/api'

            expect(subject).to be_valid
          end
        end
      end
    end
  end
end
