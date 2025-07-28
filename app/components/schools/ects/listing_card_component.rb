module Schools
  module ECTs
    class ListingCardComponent < ViewComponent::Base
      include TeacherHelper
      include ECTHelper

      attr_reader :ect_at_school_period

      def initialize(ect_at_school_period:)
        @ect_at_school_period = ect_at_school_period
      end

    private

      def appropriate_body_row
        { key: { text: 'Appropriate body' }, value: { text: ect_at_school_period.school_reported_appropriate_body_name } }
      end

      def delivery_partner_row
        return if ect_at_school_period.school_led_training_programme?

        {
          key: { text: 'Delivery partner' },
          value: { text: delivery_partner_display_text }
        }
      end

      def lead_provider_row
        return if ect_at_school_period.school_led_training_programme?

        {
          key: { text: 'Lead provider' },
          value: { text: lead_provider_display_text }
        }
      end

      def delivery_partner_display_text
        if latest_training_period_only_expression_of_interest?
          'Their lead provider will confirm this'
        else
          latest_delivery_partner_name(ect_at_school_period)
        end
      end

      def lead_provider_display_text
        if latest_training_period_only_expression_of_interest?
          latest_eoi_lead_provider_name(ect_at_school_period)
        else
          latest_lead_provider_name(ect_at_school_period)
        end
      end

      def latest_training_period_only_expression_of_interest?
        ECTAtSchoolPeriods::Training.new(ect_at_school_period).latest_training_period&.only_expression_of_interest?
      end

      def left_rows
        [status_row, trn_row, left_start_date_row].compact
      end

      def left_start_date_row
        start_date_row if ect_at_school_period.provider_led_training_programme?
      end

      def mentor_row
        { key: { text: 'Mentor', classes: %w[mentor-key] }, value: { text: ect_mentor_details(ect_at_school_period) } }
      end

      def right_rows
        [right_start_date_row, appropriate_body_row, lead_provider_row, delivery_partner_row].compact
      end

      def right_start_date_row
        start_date_row if ect_at_school_period.school_led_training_programme?
      end

      def start_date_row
        { key: { text: 'School start date' }, value: { text: ect_at_school_period.started_on.to_fs(:govuk) } }
      end

      def status_row
        { key: { text: 'Status' }, value: { text: ect_status(ect_at_school_period) } }
      end

      def trn_row
        { key: { text: 'TRN' }, value: { text: ect_at_school_period.trn } }
      end
    end
  end
end
