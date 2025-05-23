module API
  class BaseController < ActionController::Base
    include TokenAuthenticatable
  end
end
