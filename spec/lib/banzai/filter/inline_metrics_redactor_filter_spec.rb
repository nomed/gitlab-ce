require 'spec_helper'

describe Banzai::Filter::InlineMetricsRedactorFilter do
  include FilterSpecHelper

  set(:project) { create(:project) }

  let(:url) { 'https://foo.com' }
  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'without a metrics charts placeholder' do
    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  context 'with a metrics charts placeholder' do
    let(:input) do
      %(<div class="js-render-metrics") +
      %( dashboard-url="#{url}") +
      %( data-namespace="#{project.namespace.name}") +
      %( data-project="#{project.name}"></div>)
    end

    context 'no user is logged in' do
      it 'redacts the placeholder' do
        expect(doc.to_s).to eq ''
      end
    end

    context 'the user does not have permission do see charts' do
      let(:doc) { filter(input, current_user: build(:user)) }

      it 'redacts the placeholder' do
        expect(doc.to_s).to eq ''
      end
    end

    context 'the user has requisite permissions' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      it 'leaves the placeholder' do
        project.add_maintainer(user)

        expect(doc.to_s).to eq input
      end
    end
  end
end
