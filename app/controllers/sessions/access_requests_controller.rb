module Sessions
  class AccessRequestsController < ApplicationController
    before_action -> { redirect_to "/404", as: :not_found },
                  if: -> { organisation_details.blank? || role_ids.blank? }

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

    def role_ids
      # TODO: These are the codes, NOT the IDs
      # We need to either rework the DfE Sign in API so it accepts codes,
      # or we need to figure out what the IDs are and how we want to store them
      # or retrieve them across environments.
      roles = []
      if School.exists?(urn: organisation_details.fetch("dfe_sign_in_organisation_urn"))
        roles << "SchoolUser"
      end
      if AppropriateBodyPeriod.exists?(dfe_sign_in_organisation_id: organisation_details.fetch("dfe_sign_in_organisation_id"))
        roles << "AppropriateBodyUser"
      end
      roles
    end
  end
end
