module API
  class BaseController < ActionController::API
    include TokenAuthenticatable
    include ErrorRescuable
  end
end
