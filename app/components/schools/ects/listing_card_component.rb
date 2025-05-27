module Schools
  module ECTs
    class ListingCardComponent < ViewComponent::Base
      include TeacherHelper
      include ECTHelper

      attr_reader :ect

      def initialize(ect:)
        @ect = ect
      end

    private

      def appropriate_body_row
        { key: { text: 'Appropriate body' }, value: { text: ect.school_reported_appropriate_body_name } }
      end

      def delivery_partner_row
        return if ect.school_led_programme_type?

        { key: { text: 'Delivery partner' }, value: { text: latest_delivery_partner_name(ect) } }
      end

      def lead_provider_row
        return if ect.school_led_programme_type?

        { key: { text: 'Lead provider' }, value: { text: latest_lead_provider_name(ect) } }
      end

      def left_rows
        [status_row, trn_row, left_start_date_row].compact
      end

      def left_start_date_row
        start_date_row if ect.provider_led_programme_type?
      end

      def mentor_row
        { key: { text: 'Mentor', classes: %w[mentor-key] }, value: { text: ect_mentor_details(ect) } }
      end

      def right_rows
        [right_start_date_row, appropriate_body_row, lead_provider_row, delivery_partner_row].compact
      end

      def right_start_date_row
        start_date_row if ect.school_led_programme_type?
      end

      def start_date_row
        { key: { text: 'School start date' }, value: { text: ect.started_on.to_fs(:govuk) } }
      end

      def status_row
        { key: { text: 'Status' }, value: { text: ect_status(ect) } }
      end

      def trn_row
        { key: { text: 'TRN' }, value: { text: ect.trn } }
      end
    end
  end
end
