module Sessions
  class AccessRequestsController < ApplicationController
    before_action -> { redirect_to "/404", as: :not_found },
                  unless: -> { organisation_details.present? }

    def create
      DfESignIn::AccessRequestJob.perform_later(
        organisation_id: organisation_details.fetch("dfe_sign_in_organisation_id"),
        user_id: organisation_details.fetch("dfe_sign_in_user_id"),
        role_ids:
      )
    end

  private

    def organisation_details
      @organisation_details ||= session[:invalid_organisation_details]
    end

    def role_ids # TODO: These are the codes, NOT the IDs
      roles = []
      if School.exists?(urn: organisation_details.fetch("dfe_sign_in_organisationurn"))
        roles << %w[SchoolUser]
      end
      if AppropriateBodyPeriod.exists?(id: organisation_details.fetch("dfe_sign_in_organisation_id"))
        roles << %w[AppropriateBodyUser]
      end
    end
  end
end
