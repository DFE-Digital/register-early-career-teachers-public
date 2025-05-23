module API
  class BaseController < ActionController::Base
    include API::TokenAuthenticatable
  end
end
