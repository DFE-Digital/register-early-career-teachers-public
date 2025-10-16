module Schools
  module AssignExistingMentorWizard
    class Step < ApplicationWizardStep
      def self.permitted_params = []

      def save!
        persist if wizard.valid_step?
      end

      private

      def pre_populate_attributes
        # Pre-populate form fields from the MentorAssignmentContext object
        # Currently not used but implemented, once the wizard grows it should "just work"
        return unless wizard.context

        self.class.permitted_params.each do |key|
          public_send("#{key}=", wizard.context.send(key)) if wizard.context.respond_to?(key)
        end
      end

      def step_params
        @step_params ||= wizard.step_params.to_h.slice(*self.class.permitted_params.map(&:to_s))
      end
    end
  end
end
