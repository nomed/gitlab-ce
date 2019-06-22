# frozen_string_literal: true
require 'json'

module Gitlab
  module Git
    module RuggedImpl
      module UseRugged
        def use_rugged?(repo, feature)
          Gitlab::GitalyClient.can_access_disk?(repo) && Feature.enabled?(feature)
        end
      end
    end
  end
end
