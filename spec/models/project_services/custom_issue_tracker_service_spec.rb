# frozen_string_literal: true

require 'spec_helper'

describe CustomIssueTrackerService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  context 'title' do
    let(:issue_tracker) { described_class.new(properties: {}) }

    it 'sets a default title' do
      issue_tracker.title = nil

      expect(issue_tracker.title).to eq('Custom Issue Tracker')
    end

    it 'sets the custom title' do
      issue_tracker.title = 'test title'

      expect(issue_tracker.title).to eq('test title')
    end
  end

  # we need to make sure we are able to read both from properties and issue_tracker_data table
  # TODO: change this as part of #63084
  describe 'handling data fields' do
    let(:project_url) { 'http://custom.example.com/project' }
    let(:issues_url) { 'http://custom.example.com/issues' }
    let(:new_issue_url) { 'http://custom.example.com/issues/new' }

    let(:params) do
      { project_url: project_url, issues_url: issues_url, new_issue_url: new_issue_url }
    end
    let(:service_with_properties) do
      create(:redmine_service, properties: params)
    end
    let(:service_data_table) do
      create(:redmine_service, properties: nil).tap do |service|
        create(:issue_tracker_data, params.merge(service: service))
      end
    end

    context 'when data stored in properties' do
      let(:service) { service_with_properties }

      it_behaves_like 'data fields handling'
    end

    context 'when data stored in the issue_tracker_data table' do
      let(:service) { service_data_table }

      it_behaves_like 'data fields handling'
    end
  end
end
