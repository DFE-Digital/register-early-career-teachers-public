module Admin
  module AppropriateBodies
    class DescriptionComponent < ApplicationComponent
      attr_reader :appropriate_body_period

      delegate :display_name,
               :provisioning_school,
               :teaching_school_hub,
               :local_authority?,
               :teaching_school?,
               to: :appropriate_body_period

      # @param appropriate_body_period [AppropriateBodyPeriod]
      def initialize(appropriate_body_period:)
        @appropriate_body_period = appropriate_body_period
      end

      def description
        return "Pre-dates regional awards" if legacy_body?
        return if teaching_school_hub.blank?
        return "No provisioning school recorded" if provisioning_school.blank?

        "AB duties performed by #{provisioning_school.name}"
      end

      def named? = appropriate_body_period.name.present?

    private

      def legacy_body? = local_authority? || teaching_school?
    end
  end
end
