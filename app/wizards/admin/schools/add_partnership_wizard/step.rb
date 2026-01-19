module Admin
  module Schools
    module AddPartnershipWizard
      class Step < ApplicationWizardStep
        def self.permitted_params = []

        def save!
          persist if wizard.valid_step?
        end

      private

        def pre_populate_attributes
          self.class.permitted_params.each do |key|
            value = wizard.store.public_send(key)
            public_send("#{key}=", value) if value.present?
          end
        end

        def step_params
          @step_params ||= wizard.step_params.to_h.slice(*self.class.permitted_params.map(&:to_s))
        end
      end
    end
  end
end
