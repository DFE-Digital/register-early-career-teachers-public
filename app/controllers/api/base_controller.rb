module API
  class BaseController < ActionController::API
    include TokenAuthenticatable
    include Paginatable
    include ErrorRescuable
  end
end
