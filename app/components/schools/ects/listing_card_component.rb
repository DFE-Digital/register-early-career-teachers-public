module Schools
  module ECTs
    class ListingCardComponent < ApplicationComponent
      include TeacherHelper
      include ECTHelper

      attr_reader :teacher, :ect_at_school_period, :training_period, :current_school

      def initialize(teacher:, ect_at_school_period:, training_period:, current_school: nil)
        @teacher = teacher
        @ect_at_school_period = ect_at_school_period
        @training_period = training_period
        @current_school = current_school
      end

    private

      def withdrawn_warning_text
        safe_join([
          "Tell us if #{teacher_full_name(teacher)} will be ",
          govuk_link_to(
            "continuing their training or if they have left your school.",
            "#{schools_ect_path(ect_at_school_period)}#training-details",
            no_visited_state: true
          )
        ])
      end

      def withdrawn_message_text
        lead_provider_name = training_period_lead_provider_name(training_period)
        subject = lead_provider_name.presence || "The lead provider"
        verb = lead_provider_name.present? ? "have" : "has"

        "#{subject} #{verb} told us that #{teacher_full_name(teacher)} is no longer training with them. Contact them if you think this is an error."
      end

      def deferred_message_text
        lead_provider_name = lead_provider_name_for_message
        subject = lead_provider_name.presence || "The lead provider"
        verb = lead_provider_name.present? ? "have" : "has"

        "#{subject} #{verb} told us that #{teacher_full_name(teacher)}'s training is paused. Contact them if you think this is an error."
      end

      def lead_provider_name_for_message
        return nil if training_period.blank?

        if training_period_only_expression_of_interest?
          latest_eoi_lead_provider_name(ect_at_school_period)
        else
          latest_lead_provider_name(ect_at_school_period)
        end
      end

      def withdrawn?
        training_period&.status == :withdrawn
      end

      def deferred?
        training_period&.status == :deferred
      end

      def leaving_school?
        current_school && ect_at_school_period.leaving_reported_for_school?(current_school)
      end

      def exempt?
        ect_at_school_period.teacher.trs_induction_status == "Exempt"
      end

      def mentor_required_for_card?
        mentor_required?(ect_at_school_period, current_school:)
      end

      def show_lead_provider_delivery_partner_rows?
        !withdrawn?
      end

      def appropriate_body_row
        { key: { text: "Appropriate body" }, value: { text: ect_at_school_period.school_reported_appropriate_body_name } }
      end

      def delivery_partner_row
        return if training_period&.school_led_training_programme?
        return unless show_lead_provider_delivery_partner_rows?

        {
          key: { text: "Delivery partner" },
          value: { text: delivery_partner_display_text }
        }
      end

      def lead_provider_row
        return if training_period&.school_led_training_programme?
        return unless show_lead_provider_delivery_partner_rows?

        {
          key: { text: "Lead provider" },
          value: { text: lead_provider_display_text }
        }
      end

      def delivery_partner_display_text
        if training_period_only_expression_of_interest?
          "Their lead provider will confirm this"
        else
          latest_delivery_partner_name(ect_at_school_period)
        end
      end

      def lead_provider_display_text
        if training_period_only_expression_of_interest?
          latest_eoi_lead_provider_name(ect_at_school_period)
        else
          latest_lead_provider_name(ect_at_school_period)
        end
      end

      def training_period_only_expression_of_interest?
        training_period&.only_expression_of_interest?
      end

      def left_rows
        [status_row, trn_row, left_start_date_row].compact
      end

      def left_start_date_row
        start_date_row if training_period&.provider_led_training_programme?
      end

      def mentor_row
        { key: { text: "Mentor", classes: %w[mentor-key] }, value: { text: ect_mentor_details(ect_at_school_period) } }
      end

      def right_rows
        [right_start_date_row, appropriate_body_row, lead_provider_row, delivery_partner_row].compact
      end

      def right_start_date_row
        start_date_row if training_period&.school_led_training_programme?
      end

      def start_date_row
        { key: { text: "School start date" }, value: { text: ect_at_school_period.started_on.to_fs(:govuk) } }
      end

      def status_row
        return normal_status_row if leaving_school? || exempt?
        return status_override_row if withdrawn? || deferred? || mentor_required_for_card?

        normal_status_row
      end

      def normal_status_row
        { key: { text: "Status" }, value: { text: ect_status(ect_at_school_period, current_school:) } }
      end

      def trn_row
        { key: { text: "TRN" }, value: { text: teacher.trn } }
      end

      def status_override
        return ["Action required", "red", withdrawn_message_text] if withdrawn?
        return ["Training paused", "orange", deferred_message_text] if deferred?
        return ["Action required", "red", "A mentor needs to be assigned to #{teacher_full_name(teacher)}."] if mentor_required_for_card?

        nil
      end

      def status_override_row
        tag_text, colour, message = status_override

        {
          key: { text: "Status" },
          value: {
            text: safe_join(
              [
                govuk_tag(text: tag_text, colour:),
                content_tag(:p, message, class: "govuk-body govuk-!-margin-top-2")
              ]
            )
          }
        }
      end
    end
  end
end
