module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class ConfirmationStep < ApplicationWizardStep
        def self.permitted_params = []

        def previous_step = :check_answer

        def new_email = mentor.email

      private

        delegate :mentor, to: :wizard

        def pre_populate_attributes = nil
      end
    end
  end
end
