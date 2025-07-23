module API
  class BaseController < ActionController::API
    include TokenAuthenticatable
    include Paginatable
    include ErrorRescuable
    include DateFilterable
    include ContractPeriodFilterable
    include FilterValidatable
  end
end
