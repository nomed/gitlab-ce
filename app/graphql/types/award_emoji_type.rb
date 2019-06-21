# frozen_string_literal: true

module Types
  class AwardEmojiType < BaseObject
    graphql_name 'AwardEmoji'

    field :name,
          GraphQL::STRING_TYPE,
          null: false,
          description: 'The emoji name'

    field :user,
          Types::UserType,
          null: false,
          description: 'The user who awarded the emoji',
          resolve: -> (award_emoji, _args, _context) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, award_emoji.user_id).find }
  end
end
