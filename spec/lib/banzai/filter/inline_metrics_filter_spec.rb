require 'spec_helper'

describe Banzai::Filter::InlineMetricsFilter do
  include FilterSpecHelper

  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'when the document has an external link' do
    let(:url) { 'https://foo.com' }

    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  context 'when the document has a metrics dashboard link' do
    let(:url) { urls.metrics_namespace_project_environment_url('foo', 'bar', 12) }

    it 'leaves the original link unchanged' do
      expect(doc.at_css('a').to_s).to eq input
    end

    it 'appends a metrics charts placeholder after metrics links' do
      node = doc.at_css('.js-render-metrics')

      expect(node).to be_present
      expect(node.attribute('data-namespace').to_s).to eq "foo"
      expect(node.attribute('data-project').to_s).to eq "bar"
    end

    context 'when the metrics dashboard link is part of a paragraph' do
      let(:input) { %(<p>This is an <a href="#{url}">example</a> of metrics.) }

      it 'appends the charts placeholder after the enclosing paragraph' do
        expect(doc.at_css('p').to_s).to include input
        expect(doc.at_css('.js-render-metrics')).to be_present
      end
    end
  end
end
