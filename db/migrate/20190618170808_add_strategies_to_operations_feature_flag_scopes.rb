# frozen_string_literal: true

class AddStrategiesToOperationsFeatureFlagScopes < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :operations_feature_flag_scopes, :strategies, :jsonb
  end
end
