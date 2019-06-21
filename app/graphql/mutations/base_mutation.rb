# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    prepend Gitlab::Graphql::CopyFieldDescription

    field :errors, [GraphQL::STRING_TYPE],
          null: true,
          description: "Reasons why the mutation failed."

    def current_user
      context[:current_user]
    end
  end
end
