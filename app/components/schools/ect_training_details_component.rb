module Schools
  class ECTTrainingDetailsComponent < ApplicationComponent
    include ProgrammeHelper
    include TeacherHelper
    include ECTHelper

    NOT_AVAILABLE = "Not available"
    YET_TO_BE_REPORTED = "Yet to be reported by the lead provider"
    DELIVERY_PARTNER_CHANGE_HINT = "To change the delivery partner, you must contact the lead provider"

    attr_reader :ect_at_school_period

    def initialize(ect_at_school_period:, training_period:)
      @ect_at_school_period = ect_at_school_period
      @training_period = training_period
    end

    def render? = ect_at_school_period.display_training_period.present?

    def call
      tag.section(id: "training-details") do
        safe_join([
          tag.h2("Training details", class: "govuk-heading-m"),
          training_details_body
        ])
      end
    end

  private

    def training_period
      @training_period || ect_at_school_period.display_training_period
    end

    def training_details_body
      return withdrawn_training_details if withdrawn?

      govuk_summary_list(rows:)
    end

    def withdrawn?
      ect_at_school_period.display_training_status == :withdrawn
    end

    def withdrawn_training_details
      safe_join([
        withdrawn_intro_paragraph,
        select_lead_provider_paragraph,
        change_to_school_led_paragraph
      ])
    end

    def withdrawn_intro_paragraph
      tag.p(
        withdrawn_training_details_message,
        class: "govuk-body govuk-!-margin-top-2"
      )
    end

    def select_lead_provider_paragraph
      ect_name = teacher_full_name(ect_at_school_period.teacher)

      tag.p(
        safe_join([
          "You can ".html_safe,
          govuk_link_to(
            "select a lead provider",
            schools_ects_change_lead_provider_wizard_edit_path(ect_at_school_period),
            no_visited_state: true
          ),
          " for #{ect_name} if they will be continuing provider-led training.".html_safe
        ]),
        class: "govuk-body"
      )
    end

    def change_to_school_led_paragraph
      tag.p(
        safe_join([
          "You can tell us if they are ".html_safe,
          govuk_link_to(
            "changing their programme type to school-led",
            schools_ects_change_training_programme_wizard_edit_path(ect_at_school_period),
            no_visited_state: true
          ),
          ".".html_safe
        ]),
        class: "govuk-body"
      )
    end

    def withdrawn_training_details_message
      lead_provider_name = withdrawn_lead_provider_name
      subject = lead_provider_name.presence || "The lead provider"
      verb = lead_provider_name.present? ? "have" : "has"
      ect_name = teacher_full_name(ect_at_school_period.teacher)

      "#{subject} #{verb} told us that #{ect_name} is no longer training with them. Contact them if you think this is an error."
    end

    def withdrawn_lead_provider_name
      current_training_period = training_period
      return nil if current_training_period.blank?

      if current_training_period.only_expression_of_interest?
        expression_of_interest = current_training_period.expression_of_interest
        lead_provider = expression_of_interest&.lead_provider
        lead_provider&.name
      else
        current_training_period.lead_provider_name
      end
    end

    def rows
      base_rows = [training_programme_row]

      if training_period&.provider_led_training_programme?
        base_rows << lead_provider_row
        base_rows << delivery_partner_row
      end

      base_rows
    end

    def training_programme_row
      {
        key: { text: "Training programme" },
        value: { text: training_programme_display_name },
        actions: [{
          text: "Change",
          visually_hidden_text: "training programme",
          href: schools_ects_change_training_programme_wizard_edit_path(ect_at_school_period),
          classes: "govuk-link--no-visited-state"
        }]
      }
    end

    def lead_provider_row
      {
        key: { text: "Lead provider" },
        value: { text: lead_provider_display_text },
        actions: [{
          text: "Change",
          visually_hidden_text: "lead provider",
          href: schools_ects_change_lead_provider_wizard_edit_path(ect_at_school_period),
          classes: "govuk-link--no-visited-state"
        }]
      }
    end

    def delivery_partner_row
      {
        key: { text: "Delivery partner" },
        value: { text: delivery_partner_display_text }
      }
    end

    def lead_provider_display_text
      return NOT_AVAILABLE if lead_provider_name.blank?

      status_text = lead_provider_status_text(lead_provider_name)
      provider_display_with_status(lead_provider_name, status_text)
    end

    def delivery_partner_display_text
      if partnership_confirmed? && training_period.delivery_partner_name.present?
        provider_display_with_status(training_period.delivery_partner_name, DELIVERY_PARTNER_CHANGE_HINT)
      else
        YET_TO_BE_REPORTED
      end
    end

    def provider_display_with_status(provider_name, status_text)
      return NOT_AVAILABLE if provider_name.blank?

      safe_join([
        provider_name,
        tag.br,
        tag.span(status_text, class: "govuk-hint")
      ])
    end

    def lead_provider_name
      case
      when partnership_confirmed?
        training_period.lead_provider_name
      when training_period.only_expression_of_interest?
        training_period.expression_of_interest_lead_provider&.name
      end
    end

    def lead_provider_status_text(provider_name)
      case
      when partnership_confirmed?
        "Confirmed by #{provider_name}"
      when training_period.only_expression_of_interest?
        "Awaiting confirmation by #{provider_name}"
      end
    end

    def partnership_confirmed?
      training_period.school_partnership.present?
    end

    def training_programme_display_name
      TRAINING_PROGRAMME.fetch(training_period.training_programme, "Unknown")
    end
  end
end
