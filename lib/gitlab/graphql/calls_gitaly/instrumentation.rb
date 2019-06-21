# frozen_string_literal: true

module Gitlab
  module Graphql
    module CallsGitaly
      module Instrumentation
        module_function

        # Check if any `calls_gitaly: true` declarations need to be added
        def instrument(_type, field)
          type_class = field.metadata[:type_class]
          type_class.try(:calls_gitaly_check)
          field
        end
      end
    end
  end
end
