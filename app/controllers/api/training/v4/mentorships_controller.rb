module API
  module Training
    module V4
      class MentorshipsController < ActionController::API
        include API::TokenAuthenticatable

        def index
          head :ok
        end
      end
    end
  end
end
