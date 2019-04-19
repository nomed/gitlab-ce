require 'spec_helper'

describe DashboardHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#dashboard_nav_links' do
    it 'has all the expected links by default' do
      menu_items = [:projects, :groups, :activity, :milestones, :snippets]

      expect(helper.dashboard_nav_links).to contain_exactly(*menu_items)
    end

    it 'does not contain cross project elements when the user cannot read cross project' do
      expect(helper).to receive(:can?).with(user, :read_cross_project) { false }

      expect(helper.dashboard_nav_links).not_to include(:activity, :milestones)
    end
  end

  describe '#feature_entry' do
    it 'returns a link if feature is enabled' do
      entry = feature_entry('Demo', 'demo.link', true)
      expect(entry).to include('<a href="demo.link">Demo</a>')
    end

    it 'considers feature enabled by default' do
      entry = feature_entry('Demo', 'demo.link')
      expect(entry).to include('<a href="demo.link">Demo</a>')
    end

    it 'returns text if feature is disabled' do
      entry = feature_entry('Demo', 'demo.link', false)
      expect(entry).not_to include('<a href="demo.link">Demo</a>')
      expect(entry).to include('Demo')
    end

    it 'returns text if href is not provided' do
      entry = feature_entry('Demo', nil, true)
      expect(entry).not_to match(/<a[^>]+>/)
    end
  end

  describe '.has_start_trial?' do
    subject { helper.has_start_trial? }

    it { is_expected.to eq(false) }
  end
end
