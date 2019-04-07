# frozen_string_literal: true

require 'airborne'

module QA
  module Runtime
    module API
      class Client
        attr_reader :address, :user

        def initialize(address = :gitlab, personal_access_token: nil, is_new_session: true, is_new_user: false)
          @address = address
          @personal_access_token = personal_access_token
          @is_new_session = is_new_session
          @is_new_user = is_new_user
          @user = nil
        end

        def personal_access_token
          @personal_access_token ||= begin
            # you can set the environment variable GITLAB_QA_ACCESS_TOKEN
            # to use a specific access token rather than create one from the UI
            Runtime::Env.personal_access_token || create_personal_access_token
          end
        end

        private

        def create_personal_access_token
          if @is_new_session
            Runtime::Browser.visit(@address, Page::Main::Login) { do_create_personal_access_token }
          else
            do_create_personal_access_token
          end
        end

        def do_create_personal_access_token
          if @is_new_user
            @user = Resource::User.fabricate_via_browser_ui!
          else
            @user = Runtime::User
            Page::Main::Login.act { sign_in_using_credentials(@user) }
          end
          Resource::PersonalAccessToken.fabricate!.access_token
        end
      end
    end
  end
end
