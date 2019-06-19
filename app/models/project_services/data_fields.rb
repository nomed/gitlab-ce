# frozen_string_literal: true

module DataFields
  extend ActiveSupport::Concern

  class_methods do
    def data_fields(*args)
      args.each do |arg|
        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          unless method_defined?(arg)
            def #{arg}
              data_fields&.send('#{arg}') || properties.to_h['#{arg}']
            end
          end

          def #{arg}=(value)
            updated_properties['#{arg}'] = #{arg} unless #{arg}_changed?

            # TODO: this will be removed as part of #63084
            if properties?
              self.properties['#{arg}'] = value
            else
              data_fields.send("#{arg}=", value)
            end
          end

          def #{arg}_changed?
            #{arg}_touched? && #{arg} != #{arg}_was
          end

          def #{arg}_touched?
            updated_properties.include?('#{arg}')
          end

          def #{arg}_was
            updated_properties['#{arg}']
          end

          def properties?
            properties.to_h.present?
          end
        RUBY
      end
    end
  end

  included do
    has_one :issue_tracker_data, autosave: true
    has_one :jira_tracker_data#, autosave: true

    def data_fields
      raise NotImplementedError
    end
  end
end
