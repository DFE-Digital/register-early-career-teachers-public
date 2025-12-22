module Admin
  module Teachers
    class TrainingSummaryComponent < ApplicationComponent
      class UnexpectedTrainingProgrammeError < StandardError; end
      attr_reader :training_period, :show_move_partnership_link

      def initialize(training_period:, show_move_partnership_link: false)
        @training_period = training_period
        @show_move_partnership_link = show_move_partnership_link
      end

      def call
        govuk_summary_card(title: card_title) do |card|
          if show_move_partnership_link?
            card.with_action { helpers.govuk_link_to("Move to a different partnership", move_partnership_path) }
          end
          card.with_summary_list do |list|
            rows.each do |row|
              list.with_row do |r|
                r.with_key(text: row[:key][:text]) if row[:key].present?
                r.with_value(text: row[:value][:text])
              end
            end
          end
        end
      end

    private

      def rows
        if training_period.provider_led_training_programme?
          provider_led_rows
        elsif training_period.school_led_training_programme?
          school_led_rows
        else
          raise UnexpectedTrainingProgrammeError, "Unexpected training programme: #{training_period.training_programme}"
        end
      end

      def provider_led_rows
        [
          summary_row("Lead provider", lead_provider_text),
          summary_row("Delivery partner", delivery_partner_text),
          summary_row("School", training_school_name),
          summary_row("Contract period", contract_period_text),
          training_programme_row,
          summary_row("Schedule", schedule_text),
          summary_row("Start date", start_date_text),
          summary_row("End date", end_date_text),
          summary_row("API response", api_response_text)
        ].compact
      end

      def school_led_rows
        [
          summary_row("School", training_school_name),
          summary_row("Training programme", TRAINING_PROGRAMME[training_period.training_programme]),
          summary_row("Start date", start_date_text),
          summary_row("End date", end_date_text)
        ]
      end

      def card_title
        return "School-led training programme" if training_period.school_led_training_programme?
        return provider_led_card_title if confirmed_partnership?

        training_period.expression_of_interest_lead_provider&.name
      end

      def provider_led_card_title
        "#{training_period.lead_provider_name} & #{training_period.delivery_partner_name}"
      end

      def lead_provider_text
        return training_period.lead_provider_name if confirmed_partnership?

        name = training_period.expression_of_interest_lead_provider&.name
        return "Not available" if name.blank?

        helpers.safe_join([
          name,
          helpers.tag.br,
          helpers.tag.span("Awaiting confirmation by #{name}", class: "govuk-hint")
        ])
      end

      def confirmed_partnership?
        training_period.school_partnership.present?
      end

      def delivery_partner_text
        if confirmed_partnership?
          training_period.delivery_partner_name
        else
          "No delivery partner confirmed"
        end
      end

      def schedule_text
        training_period.schedule&.identifier
      end

      def contract_period_text
        training_period.contract_period&.year || training_period.expression_of_interest_contract_period&.year
      end

      def not_available_text
        "Not available"
      end

      def training_school_name
        if training_period.for_ect?
          training_period.ect_at_school_period&.school&.name
        elsif training_period.for_mentor?
          training_period.mentor_at_school_period&.school&.name
        else
          not_available_text
        end
      end

      def start_date_text
        format_date(training_period.started_on)
      end

      def end_date_text
        training_period.finished_on.present? ? format_date(training_period.finished_on) : "No end date recorded"
      end

      def training_programme_row
        return if training_period.for_mentor?

        summary_row("Training programme", TRAINING_PROGRAMME[training_period.training_programme])
      end

      # TODO: get formatting of api data correct
      # Text spills over container, is not in code format, background colour is missing
      def api_response_text
        govuk_details(summary_text: "See this participant as they appear over the API for #{lead_provider&.name}") do
          content_tag(:pre) do
            content_tag(:code, serialized_teacher)
          end
        end
      end

      def lead_provider
        return training_period.lead_provider if confirmed_partnership?

        training_period.expression_of_interest_lead_provider
      end

      def serialized_teacher
        API::TeacherSerializer.render(teacher, root: "data", **{lead_provider_id: lead_provider.id})
      end

      def teacher
        return training_period.ect_at_school_period.teacher if training_period.for_ect?

        training_period.mentor_at_school_period.teacher
      end

      def format_date(date)
        date&.to_fs(:govuk)
      end

      def summary_row(label, value)
        {
          key: { text: label },
          value: { text: value.presence || not_available_text }
        }
      end

      def show_move_partnership_link?
        show_move_partnership_link &&
          training_period.provider_led_training_programme? &&
          training_period.finished_on.nil?
      end

      def move_partnership_path
        teacher_id = training_period.teacher_id
        return if teacher_id.blank?

        new_admin_teacher_training_period_partnership_path(teacher_id, training_period)
      end
    end
  end
end
