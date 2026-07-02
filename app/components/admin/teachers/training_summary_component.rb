module Admin
  module Teachers
    class TrainingSummaryComponent < ApplicationComponent
      class UnexpectedTrainingProgrammeError < StandardError; end
      attr_reader :training_period, :show_api_row

      def initialize(training_period:, show_api_row: false)
        @training_period = training_period
        @show_api_row = show_api_row
      end

      def call
        govuk_summary_card(title: card_title) do |card|
          if show_move_partnership_link?
            card.with_action { helpers.govuk_link_to("Move to a different partnership", move_partnership_path) }
          end

          helpers.safe_join([
            status_inset_text,
            helpers.govuk_summary_list(actions: false) do |list|
              rows.each do |row|
                list.with_row do |r|
                  r.with_key(text: row.dig(:key, :text)) if row[:key].present?
                  r.with_value(text: row.dig(:value, :text))
                end
              end
            end
          ].compact)
        end
      end

    private

      def status_inset_text
        case training_period.status
        when :deferred
          helpers.govuk_inset_text(text: "#{helpers.teacher_full_name(teacher)} has been deferred from this training period by the lead provider.")
        when :withdrawn
          helpers.govuk_inset_text(text: "#{helpers.teacher_full_name(teacher)} has been withdrawn from this training period by the lead provider.")
        end
      end

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
          api_response_row,
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

      def api_response_row
        return unless show_api_row

        summary_row("API response", api_response_text)
      end

      def api_response_text
        govuk_details(summary_text: "See this participant as they appear over the API for #{lead_provider&.name}") do
          tag.pre { tag.code(formatted_teacher) }
        end
      end

      def lead_provider
        return training_period.lead_provider if confirmed_partnership?

        training_period.expression_of_interest_lead_provider
      end

      def serialized_teacher
        API::TeacherSerializer.render(teacher, root: "data", **{ lead_provider_id: lead_provider.id })
      rescue Enumerable::SoleItemExpectedError
        nil
      end

      def formatted_teacher
        return "Partnership not confirmed for this participant" unless confirmed_partnership?
        return "No API data for this participant" if serialized_teacher.nil?

        @formatted_teacher ||= JSON.pretty_generate(JSON.parse(serialized_teacher))
      end

      def teacher
        return training_period.ect_at_school_period.teacher if training_period.for_ect?

        training_period.mentor_at_school_period.teacher
      end

      def format_date(date)
        date&.to_fs(:govuk)
      end

      def show_move_partnership_link?
        @show_move_partnership_link ||= show_api_row &&
          training_period.provider_led_training_programme? &&
          training_period.finished_on.nil?
      end

      def summary_row(label, value)
        {
          key: { text: label },
          value: { text: value.presence || not_available_text }
        }
      end

      def move_partnership_path
        teacher_id = training_period.teacher_id
        return if teacher_id.blank?

        new_admin_teacher_training_period_partnership_path(teacher_id, training_period)
      end
    end
  end
end
