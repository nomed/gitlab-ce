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
          if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
            Page::Main::Menu.perform { |main| main.sign_out }
          end

          Page::Main::Login.perform { |login| login.sign_in_using_credentials(@user) }
          Resource::PersonalAccessToken.fabricate!.access_token
        end
      end
    end
  end
end
