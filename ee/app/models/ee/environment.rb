# frozen_string_literal: true

module EE
  module Environment
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      has_many :prometheus_alerts, inverse_of: :environment
      has_one :last_deployable, through: :last_deployment, source: 'deployable', source_type: 'CommitStatus'
      has_one :last_pipeline, through: :last_deployable, source: 'pipeline'
    end

    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def clear_prometheus_reactive_cache!(query_name)
      cluster_prometheus_adapter&.clear_prometheus_reactive_cache!(query_name, self)
    end

    def cluster_prometheus_adapter
      @cluster_prometheus_adapter ||= Prometheus::AdapterService.new(project, deployment_platform).cluster_prometheus_adapter
    end

    def protected?
      project.protected_environment_by_name(name).present?
    end

    def protected_deployable_by_user?(user)
      project.protected_environment_accessible_to?(name, user)
    end

    override :has_terminals?
    def has_terminals?
      deployment_platform.present? && available? && last_deployment.present?
    end

    override :terminals
    def terminals
      deployment_platform.terminals(self) if has_terminals?
    end

    def rollout_status
      deployment_platform.rollout_status(self) if has_terminals?
    end
  end
end