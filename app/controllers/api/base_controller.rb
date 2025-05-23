module API
  class BaseController < ActionController::Base
    include TokenAuthenticatable
    include Paginatable
  end
end
