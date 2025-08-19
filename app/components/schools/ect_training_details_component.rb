# frozen_string_literal: true

module Schools
  class ECTTrainingDetailsComponent < ViewComponent::Base
    include ProgrammeHelper

    def initialize(ect)
      @ect = ect
    end

    def call
      safe_join([
        tag.h2('Training details', class: 'govuk-heading-m'),
        govuk_summary_list(rows:)
      ])
    end

  private

    def training
      @training ||= ECTAtSchoolPeriods::CurrentTraining.new(@ect)
    end

    def rows
      base_rows = [training_programme_row]

      if training.provider_led?
        base_rows << lead_provider_row
        base_rows << delivery_partner_row
      end

      base_rows
    end

    def training_programme_row
      { key: { text: 'Training programme' }, value: { text: training_programme_display_name } }
    end

    def lead_provider_row
      {
        key: { text: 'Lead provider' },
        value: { text: lead_provider_display_text }
      }
    end

    def delivery_partner_row
      {
        key: { text: 'Delivery partner' },
        value: { text: delivery_partner_display_text }
      }
    end

    def lead_provider_display_text
      return fallback_lead_provider_name unless partnership_confirmed? || training.expression_of_interest?

      if partnership_confirmed?
        provider_name = training.lead_provider_name
        status_text = "Confirmed by #{provider_name}"
      else
        provider_name = training.expression_of_interest_lead_provider_name
        status_text = "Awaiting confirmation by #{provider_name}"
      end

      return 'Not available' if provider_name.blank?

      safe_join([
        provider_name,
        tag.br,
        tag.span(status_text, class: 'govuk-hint')
      ])
    end

    def delivery_partner_display_text
      return yet_to_be_reported_message unless partnership_confirmed? && training.delivery_partner_name.present?

      safe_join([
        training.delivery_partner_name,
        tag.br,
        tag.span("To change the delivery partner, you must contact the lead provider", class: 'govuk-hint')
      ])
    end

    def partnership_confirmed?
      training.school_partnership.present?
    end

    def fallback_lead_provider_name
      training.lead_provider_name || training.expression_of_interest_lead_provider_name || 'Not available'
    end

    def yet_to_be_reported_message
      'Yet to be reported by the lead provider'
    end

    def training_programme_display_name
      case training.training_programme
      when 'provider_led'
        'Provider-led'
      when 'school_led'
        'School-led'
      else
        training.training_programme&.humanize || 'Unknown'
      end
    end
  end
end
