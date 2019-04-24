# frozen_string_literal: true

# Finder for retrieving project registries that verification have
# failed scoped to a type (repository or wiki) using cross-database
# joins for selective sync.
#
# Basic usage:
#
#     Geo::LegacyProjectRegistryVerificationFailedFinder.new(current_node: Gitlab::Geo.current_node, :repository).execute
#
# Valid `type` values are:
#
# * `:repository`
# * `:wiki`
#
# Any other value will be ignored.
module Geo
  class LegacyProjectRegistryVerificationFailedFinder < RegistryFinder
    def initialize(current_node: nil, type:)
      super(current_node: current_node)
      @type = type.to_s.to_sym
    end

    def execute
      legacy_inner_join_registry_ids(
        Geo::ProjectRegistry.verification_failed(type),
        current_node.projects.pluck_primary_key,
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end

    private

    attr_reader :type
  end
end