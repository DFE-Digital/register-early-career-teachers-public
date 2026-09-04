class CheckValidityJob < ApplicationJob
  queue_as :check_validity

  def perform
    raise CheckValidity::ProductionGuardError, "Do not query live production data" if Rails.env.production?

    CheckValidity.new.call
  end
end
