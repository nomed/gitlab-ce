# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class ResetCommand
        include BaseCommand

        attr_reader :name, :files

        def initialize(name:, rbac:, files:)
          @name = name
          @files = files
          @rbac = rbac
        end

        def generate_script
          super + [
            reset_helm_command
          ].join("\n")
        end

        def rbac?
          @rbac
        end

        def pod_name
          "uninstall-#{name}"
        end

        private

        def reset_helm_command
          command = %w[helm reset] + optional_tls_flags

          command.shelljoin
        end

        def optional_tls_flags
          return [] unless files.key?(:'ca.pem')

          [
            '--tls',
            '--tls-ca-cert', "#{files_dir}/ca.pem",
            '--tls-cert', "#{files_dir}/cert.pem",
            '--tls-key', "#{files_dir}/key.pem"
          ]
        end
      end
    end
  end
end
