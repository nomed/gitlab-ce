# frozen_string_literal: true

module AwardEmojis
  class BaseService < ::BaseService
    attr_accessor :awardable, :name

    def initialize(awardable, name, user)
      @awardable = awardable
      @name = normalize_name(name)

      # The only reason I'm passing in project is to
      # inherit from ::BaseService, in order to get the
      # success and error things, but perhaps I could extract that
      # into a module
      super(awardable.project, user)
    end

    private

    def normalize_name(name)
      Gitlab::Emoji.normalize_emoji_name(name)
    end
  end
end
