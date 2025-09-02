module Schools
  class ECTTrainingDetailsComponent < ViewComponent::Base
    include ProgrammeHelper

    attr_reader :ect_at_school_period, :training_period

    def initialize(ect_at_school_period:, training_period:)
      @ect_at_school_period = ect_at_school_period
      @training_period = training_period
    end

    def render? = @training_period.present?

    def call
      safe_join([
        tag.h2('Training details', class: 'govuk-heading-m'),
        govuk_summary_list(rows:)
      ])
    end

  private

    def rows
      base_rows = [training_programme_row]

      if training_period.provider_led_training_programme?
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
      return fallback_lead_provider_name unless partnership_confirmed? || training_period.only_expression_of_interest?

      if partnership_confirmed?
        provider_name = training_period.lead_provider_name
        status_text = "Confirmed by #{provider_name}"
      else
        provider_name = training_period.expression_of_interest_lead_provider_name
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
      return yet_to_be_reported_message unless partnership_confirmed? && training_period.delivery_partner_name.present?

      safe_join([
        training_period.delivery_partner_name,
        tag.br,
        tag.span("To change the delivery partner, you must contact the lead provider", class: 'govuk-hint')
      ])
    end

    def partnership_confirmed?
      training_period.school_partnership.present?
    end

    def fallback_lead_provider_name
      training_period.lead_provider_name || training_period.expression_of_interest_lead_provider_name || 'Not available'
    end

    def yet_to_be_reported_message
      'Yet to be reported by the lead provider'
    end

    def training_programme_display_name
      TRAINING_PROGRAMME.fetch(training_period.training_programme, 'Unknown')
    end
  end
end
