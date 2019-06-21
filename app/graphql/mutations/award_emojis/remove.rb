# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Remove < Base
      graphql_name 'RemoveAwardEmoji'

      def resolve(args)
        awardable = authorized_find_with_pre_checks!(id: args[:awardable_id]) do |object|
          # Validate that the object is able an Awardable before authorizing.
          # This allows us to raise a friendly error message before authorization happens.
          check_object_is_awardable!(object)
        end

        # TODO this check can be removed once AwardEmoji services are available.
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        unless awardable.awarded_emoji?(args[:name], current_user)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'You have not awarded emoji of type name to the awardable'
        end

        # TODO this will be handled by AwardEmoji::DestroyService
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        awardable.remove_award_emoji(args[:name], current_user)

        {
          # Mutation response is always a `nil` award_emoji
        }
      end
    end
  end
end
