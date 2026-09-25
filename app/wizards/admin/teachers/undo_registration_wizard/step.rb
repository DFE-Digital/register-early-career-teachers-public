module Admin
  module Teachers
    module UndoRegistrationWizard
      class Step < ApplicationWizardStep
        def self.permitted_params = []

        def self.permitted_param_names
          permitted_params.flat_map { |param| param.is_a?(Hash) ? param.keys : param }
        end

        def save!
          return false unless wizard.valid_step?

          persist
          true
        end

      private

        def any_permitted_param?(args)
          args.keys.map(&:to_sym).intersect?(self.class.permitted_param_names)
        end

        def pre_populate_attributes
          self.class.permitted_param_names.each do |key|
            value = wizard.store.public_send(key)
            public_send("#{key}=", value) if value.present?
          end
        end

        def step_params
          @step_params ||= wizard.step_params.to_h.slice(*self.class.permitted_param_names.map(&:to_s))
        end
      end
    end
  end
end
