require 'spec_helper'

describe 'layouts/nav/sidebar/_group' do
  before do
    assign(:group, create(:group))
  end

  describe 'contribution analytics tab' do
    it 'is not visible when there is no valid license and we dont show promotions' do
      stub_licensed_features(contribution_analytics: false)

      render

      expect(rendered).not_to have_text 'Contribution Analytics'
    end

    context 'no license installed' do
      let!(:cuser) { create(:admin) }

      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(check_namespace_plan: false)

        allow(view).to receive(:can?) { |*args| Ability.allowed?(*args) }
        allow(view).to receive(:current_user).and_return(cuser)
      end

      it 'is visible when there is no valid license but we show promotions' do
        stub_licensed_features(contribution_analytics: false)

        render

        expect(rendered).to have_text 'Contribution Analytics'
      end
    end

    it 'is visible' do
      stub_licensed_features(contribution_analytics: true)

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end

    describe 'group issue boards link' do
      context 'when multiple issue board is disabled' do
        it 'shows link text in singular' do
          render

          expect(rendered).to have_text 'Board'
        end
      end

      context 'when multiple issue board is enabled' do
        before do
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        it 'shows link text in plural' do
          render

          expect(rendered).to have_text 'Boards'
        end
      end
    end
  end

  describe 'security dashboard tab' do
    it 'is visible when user has enough permission' do
      allow(view).to receive(:can?)
        .with(anything, :read_group_security_dashboard, anything)
        .and_return(true)

      render

      expect(rendered).to have_text 'Security Dashboard'
    end

    it 'is not visible when user does not have enough permission' do
      allow(view).to receive(:can?)
        .with(anything, :read_group_security_dashboard, anything)
        .and_return(false)

      render

      expect(rendered).not_to have_text 'Security Dashboard'
    end
  end
end