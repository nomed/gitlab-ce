require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::IssueStage do
  HALF_AN_HOUR_IN_SECONDS = 60 * 30

  let(:stage_name) { :issue }

  it_behaves_like 'base stage'

  describe '#median' do
    let(:project) { create(:project) }
    let!(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
    let!(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
    let!(:issue_3) { create(:issue, project: project, created_at: 30.minute.ago) }
    let!(:issue_without_milestone) { create(:issue, project: project, created_at: 1.minute.ago) }
    let(:stage) { described_class.new(project: project, options: { from: 2.days.ago }) }

    before do
      issue_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago)
      issue_2.metrics.update!(first_added_to_board_at: 30.minutes.ago)
      issue_3.metrics.update!(first_added_to_board_at: 15.minutes.ago)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    it 'counts median from issues with metrics' do
      expect(stage.median).to eq(HALF_AN_HOUR_IN_SECONDS)
    end
  end
end
