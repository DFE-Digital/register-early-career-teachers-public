module Admin
  module AppropriateBodies
    class DescriptionComponent < ApplicationComponent
      attr_reader :appropriate_body_period

      delegate :display_name,
               :provisioning_school,
               :teaching_school_hub,
               :local_authority?,
               :teaching_school?,
               :region_awards,
               to: :appropriate_body_period

      # @param appropriate_body_period [AppropriateBodyPeriod]
      def initialize(appropriate_body_period:)
        @appropriate_body_period = appropriate_body_period
      end

      def description
        return "Pre-dates regional awards" if legacy_body?
        return if teaching_school_hub.blank?
        return "No provisioning school recorded" if provisioning_school.blank?

        "Provisioned by #{provisioning_school.name}, #{region_summary}"
      end

      def named? = appropriate_body_period.name.present?

    private

      def legacy_body? = local_authority? || teaching_school?

      def region_count = region_awards.count(&:active?)

      def region_summary
        return "no regions awarded" if region_count.zero?

        "awarded #{region_count} #{'region'.pluralize(region_count)}"
      end
    end
  end
end
