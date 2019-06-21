# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Add < Base
      graphql_name 'AddAwardEmoji'

      def resolve(args)
        awardable = authorized_find_with_pre_checks!(id: args[:awardable_id]) do |object|
          # Validate that the object is able an Awardable before authorizing.
          # This allows us to raise a friendly error message before authorization happens.
          check_object_is_awardable!(object)
        end

        # TODO this will be handled by AwardEmoji::AddService
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        award = awardable.create_award_emoji(args[:name], current_user)

        # MR note - this makes the 'error' state consistent with authorization errors
        # i.e., the front-end just has to expect errors to be in one structure.
        # I think we should change MR WIP to do the same. In the meantime the errors field
        # is now optional rather than required
        unless award.valid?
          raise Gitlab::Graphql::Errors::MutationError, award.errors.full_messages.to_sentence
        end

        {
          award_emoji: award
        }
      end
    end
  end
end
