module Sessions
  class AccessRequestsController < ApplicationController
    before_action -> { render "errors/not_found", status: :not_found },
                  unless: -> { dfe_sign_in_organisation_details.access_requestable? },
                  only: :create

    def create
      ::DfESignIn::AccessRequestJob.perform_later(
        organisation_id: dfe_sign_in_organisation_details.organisation_id,
        user_id: dfe_sign_in_organisation_details.user_id,
        role_ids: dfe_sign_in_organisation_details.role_ids
      )
      session.delete(:invalid_organisation_details)
      redirect_to confirmation_sessions_access_request_path
    end

    def confirmation
    end

  private

    def dfe_sign_in_organisation_details
      @dfe_sign_in_organisation_details ||= DfESignIn::OrganisationDetails.new(
        session[:invalid_organisation_details]
      )
    end
  end
end
