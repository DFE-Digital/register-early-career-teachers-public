module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class CheckAnswerStep < ApplicationWizardStep
        def self.permitted_params = []

        def previous_step = :edit
        def next_step = :confirmation

        def save!
          mentor.update!(email: new_email)
        end

        def current_email = mentor.email
        def new_email = store.email

      private

        delegate :mentor, to: :wizard

        def pre_populate_attributes = nil
      end
    end
  end
end
