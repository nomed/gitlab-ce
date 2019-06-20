# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateNullPrivateProfileToFalse
      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      def perform(start_id, stop_id)
        User.where(private_profile: nil, id: start_id..stop_id).update_all(private_profile: false)
      end
    end
  end
end
