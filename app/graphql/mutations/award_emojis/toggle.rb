# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Toggle < Base
      graphql_name 'ToggleAwardEmoji'

      field :toggledOn,
            GraphQL::BOOLEAN_TYPE,
            null: false,
            description: 'True when the emoji was awarded, false when it was removed'

      def resolve(args)
        awardable = authorized_find_with_pre_checks!(id: args[:awardable_id]) do |object|
          # Validate that the object is able an Awardable before authorizing.
          # This allows us to raise a friendly error message before authorization happens.
          check_object_is_awardable!(object)
        end

        # TODO this will be handled by AwardEmoji::ToggleService
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        award = awardable.toggle_award_emoji(args[:name], current_user)

        # Destroy returns a collection :(
        award = award.first if award.is_a?(Array)

        unless award.valid?
          raise Gitlab::Graphql::Errors::MutationError, award.errors.full_messages.to_sentence
        end

        # I think we should return a nil for award_emoji if this was a destroy....
        # To be consistent with the destroy mutation
        toggled_on = awardable.awarded_emoji?(args[:name], current_user)

        {
          # award_emoji will be presented if the award was created and
          # If award_emoji was destroyed, display `nil`
          award_emoji: (award if toggled_on), # Test that invalid awards are returned as nil, also note this in MR
          toggled_on: toggled_on
        }
      end
    end
  end
end
