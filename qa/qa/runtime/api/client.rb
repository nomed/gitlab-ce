# frozen_string_literal: true

require 'airborne'

module QA
  module Runtime
    module API
      class Client
        attr_reader :address, :user

        def initialize(address = :gitlab, personal_access_token: nil, is_new_session: true, user: nil)
          @address = address
          @personal_access_token = personal_access_token
          @is_new_session = is_new_session
          @user = user
        end

        def personal_access_token
          @personal_access_token ||= begin
            # you can set the environment variable GITLAB_QA_ACCESS_TOKEN
            # to use a specific access token rather than create one from the UI
            # unless a specific user has been passed
            @user.nil? && Runtime::Env.personal_access_token ? Runtime::Env.personal_access_token : create_personal_access_token
          end
        end

        private

        def create_personal_access_token
          Runtime::Browser.visit(@address, Page::Main::Login) if @is_new_session
          do_create_personal_access_token
        end

        def do_create_personal_access_token
          if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
            Page::Main::Menu.perform(&:sign_out)
          end

          Page::Main::Login.perform(&:sign_in_using_credentials(@user))
          Resource::PersonalAccessToken.fabricate!.access_token
        end
      end
    end
  end
end
