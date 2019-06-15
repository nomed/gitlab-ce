# frozen_string_literal: true
require 'json'

module Gitlab
  module Git
    module RuggedImpl
      module UseRugged
        MUTEX = Mutex.new

        def self.use_rugged?(repo, feature)
          can_access_disk?(repo) && Feature.enabled?(feature)
        end

        def self.filesystem_ids_from_disk
          @filesystem_ids_from_disk ||= {}
        end

        def self.filesystem_ids_from_gitaly
          @filesystem_ids_from_gitaly ||= {}
        end

        def self.filesystem_id_from_disk(repo)
          MUTEX.synchronize do
            filesystem_ids_from_disk[repo.storage] = retrieve_filesystem_id_from_disk(repo) unless filesystem_ids_from_disk[repo.storage].present?
          end
        rescue Errno::ENOENT
          ''
        end

        def self.retrieve_filesystem_id_from_disk(repo)
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            metadata_file = File.read(repo.path_to_gitaly_metadata_file)
            metadata_hash = JSON.parse(metadata_file)
            metadata_hash['gitaly_filesystem_id']
          end
        end

        def self.filesystem_id_from_gitaly(repo)
          MUTEX.synchronize do
            filesystem_ids_from_gitaly[repo.storage] = Gitlab::GitalyClient.filesystem_id(repo.storage) unless filesystem_ids_from_gitaly[repo.storage].present?
          end
        end

        def self.can_access_disk?(repo)
          from_disk, from_gitaly = filesystem_id_from_disk(repo), filesystem_id_from_gitaly(repo)
          return false unless from_disk.present? && from_gitaly.present?

          from_disk == from_gitaly
        end
      end
    end
  end
end
