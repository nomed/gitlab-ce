# frozen_string_literal: true

class Namespace::AggregationSchedule < ApplicationRecord
  include AfterCommitQueue
  include ExclusiveLeaseGuard

  LEASE_TIMEOUT = 3.hours
  DEFAULT_STATISTICS_DELAY = 3.hours
  REDIS_SHARED_KEY = 'gitlab:update_namespace_statistics_delay'.freeze

  belongs_to :namespace

  after_create :schedule_root_storage_statistics

  private

  def schedule_root_storage_statistics
    run_after_commit do
      try_obtain_lease do
        Namespaces::RootStatisticsWorker
          .perform_async(namespace_id)

        Namespaces::RootStatisticsWorker
          .perform_in(delay_timeout, namespace_id)
      end
    end
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def delay_timeout
    redis_delay_timeout || DEFAULT_STATISTICS_DELAY
  end

  def redis_delay_timeout
    timeout = Gitlab::Redis::SharedState.with do |redis|
      redis.get(REDIS_SHARED_KEY)
    end

    timeout.nil? ? timeout : timeout.to_i
  end

  def lease_key
    "namespace:namespaces_root_statistics:#{namespace_id}"
  end
end
