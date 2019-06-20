# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AggregationSchedule, type: :model do
  include ExclusiveLeaseHelpers

  it { is_expected.to belong_to :namespace }

  describe '#schedule_root_storage_statistics', :clean_gitlab_redis_shared_state do
    let(:namespace) { create(:namespace) }
    let(:aggregation_schedule) { namespace.build_aggregation_schedule }
    let(:lease_key) { "namespace:namespaces_root_statistics:#{namespace.id}" }
    let(:lease_timeout) { 3.hours }

    context "when we can't obtain the lease" do
      it 'does not schedule the workers' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_async)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_in)

        aggregation_schedule.save!
      end
    end

    context 'when we can obtain the lease' do
      it 'schedules a root storage statistics after create' do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once

        aggregation_schedule.save!
      end
    end

    context 'with a personalized lease timeout' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::REDIS_SHARED_KEY, 1.hour)
        end
      end

      it 'uses a personalized time' do
        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in)
          .with(1.hour, aggregation_schedule.namespace_id)

        aggregation_schedule.save!
      end
    end

    context 'without a personalized lease timeout' do
      it 'uses the default timeout' do
        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in)
          .with(described_class::DEFAULT_STATISTICS_DELAY, aggregation_schedule.namespace_id )

        aggregation_schedule.save!
      end
    end
  end
end
