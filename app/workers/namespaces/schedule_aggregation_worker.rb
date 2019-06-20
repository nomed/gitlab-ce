# frozen_string_literal: true

module Namespaces
  class ScheduleAggregationWorker
    include ApplicationWorker

    queue_namespace :update_namespace_statistics

    def perform(namespace_id)
      return unless aggregation_schedules_table_exists?

      namespace = Namespace.find(namespace_id)
      root_ancestor = namespace.root_ancestor

      return if root_ancestor.aggregation_scheduled?

      root_ancestor.create_aggregation_schedule!
    rescue ActiveRecord::RecordNotFound
      log_error(namespace_id)
    end

    private

    # On db/post_migrate/20180529152628_schedule_to_archive_legacy_traces.rb
    # traces are archived through build.trace.archive, which in consequence
    # calls UpdateProjectStatistics#schedule_namespace_statistics_worker.
    #
    # The migration fails since NamespaceAggregationSchedule table
    # does not exist at that point.
    def aggregation_schedules_table_exists?
      Namespace::AggregationSchedule.table_exists?
    end

    def log_error(namespace_id)
      Gitlab::SidekiqLogger.error("Namespace can't be scheduled for aggregation: #{namespace_id} does not exist")
    end
  end
end
