# frozen_string_literal: true

require 'spec_helper'

describe Namespaces::StatisticsRefresherService, '#execute' do
  let(:group) { create(:group) }
  let(:projects) { create_list(:project, 5, namespace: group) }
  let(:service) { described_class.new }

  context 'without a root storage statistics relation' do
    it 'creates one' do
      expect do
        service.execute(group)
      end.to change(Namespace::RootStorageStatistics, :count).by(1)
    end

    it 'recalculate the namespace statistics' do
      expect_any_instance_of(Namespace::RootStorageStatistics).to receive(:recalculate!).once

      service.execute(group)
    end
  end

  context 'with a root storage statistics relation' do
    before do
      group.create_root_storage_statistics!
    end

    it 'does not create one' do
      expect do
        service.execute(group)
      end.not_to change(Namespace::RootStorageStatistics, :count)
    end

    it 'recalculate the namespace statistics' do
      expect(group.root_storage_statistics).to receive(:recalculate!).once

      service.execute(group)
    end
  end

  context 'when something goes wrong' do
    before do
      allow_any_instance_of(Namespace::RootStorageStatistics)
        .to receive(:recalculate!).and_raise(ActiveRecord::ActiveRecordError)
    end

    it 'raises RefreshError' do
      expect do
        service.execute(group)
      end.to raise_error(Namespaces::StatisticsRefresherService::RefresherError)
    end
  end
end
