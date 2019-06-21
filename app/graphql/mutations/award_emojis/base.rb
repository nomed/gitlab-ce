# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Base < BaseMutation
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :award_emoji

      argument :awardable_id,
            GraphQL::ID_TYPE,
            required: true,
            description: 'The global id of the awardable resource'

      argument :name,
            GraphQL::STRING_TYPE,
            required: true,
            description: copy_field_description(Types::AwardEmojiType, :name)

      field :award_emoji,
            Types::AwardEmojiType,
            null: true,
            description: 'The award emoji after mutation'

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end

      # Called by mutations methods before performing an authorization check
      # of an awardable object.
      def check_object_is_awardable!(object)
        unless object.class.included_modules.include?(Awardable)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'The resource of awardable_id can not be awarded emojis'
        end

        # TODO this check be removed when AwardEmoji services are available
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        unless object.emoji_awardable?
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'The resource is not emoji awardable'
        end
      end
    end
  end
end
