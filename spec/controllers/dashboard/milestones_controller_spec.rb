# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::MilestonesController do
  let(:project) { create(:project) }
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:project_milestone) { create(:milestone, project: project) }
  let(:group_milestone) { create(:milestone, group: group) }
  let(:milestone) { create(:milestone, group: group) }
  let(:issue) { create(:issue, project: project, milestone: project_milestone) }
  let(:group_issue) { create(:issue, milestone: group_milestone, project: create(:project, group: group)) }

  let!(:label) { create(:label, project: project, title: 'Issue Label', issues: [issue]) }
  let!(:group_label) { create(:group_label, group: group, title: 'Group Issue Label', issues: [group_issue]) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: project_milestone) }
  let(:milestone_path) { dashboard_milestone_path(milestone.safe_title, title: milestone.title) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_developer(user)
  end

  describe "#index" do
    let(:public_group) { create(:group, :public) }
    let!(:public_milestone) { create(:milestone, group: public_group) }

    render_views

    it 'returns group and project milestones to which the user belongs' do
      get :index, format: :json

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |i| i["title"] }).to match_array([group_milestone.title, project_milestone.title])
    end

    it 'searches legacy project milestones by title when search_title is given' do
      project_milestone = create(:milestone, title: 'Project milestone title', project: project)

      get :index, params: { search_title: 'Project mil' }

      expect(response.body).to include(project_milestone.title)
      expect(response.body).not_to include(group_milestone.title)
    end

    it 'searches group milestones by title when search_title is given' do
      group_milestone = create(:milestone, title: 'Group milestone title', group: group)

      get :index, params: { search_title: 'Group mil' }

      expect(response.body).to include(group_milestone.title)
      expect(response.body).not_to include(project_milestone.title)
    end

    it 'shows counts of group and project milestones to which the user belongs to' do
      get :index

      expect(response.body).to include("Open\n<span class=\"badge badge-pill\">2</span>")
      expect(response.body).to include("Closed\n<span class=\"badge badge-pill\">0</span>")
    end

    context 'external authorization' do
      subject { get :index }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end
end
