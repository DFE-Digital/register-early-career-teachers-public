module Schools
  module RegisterECTWizard
    class AppropriateBodyStep < Step
      attr_accessor :appropriate_body_id

      validates :appropriate_body, appropriate_body: true

      def self.permitted_params = %i[appropriate_body_id]

      def appropriate_body
        @appropriate_body ||= AppropriateBody.find_by_id(appropriate_body_id) if appropriate_body_id
      end

      def appropriate_body_type = appropriate_body&.body_type

      def next_step = :programme_type

      def previous_step
        return :use_previous_ect_choices if school.last_programme_choices?

        :working_pattern
      end
    end
  end
end
