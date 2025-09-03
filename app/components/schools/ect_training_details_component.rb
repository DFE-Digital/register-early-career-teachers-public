module Schools
  class ECTTrainingDetailsComponent < ViewComponent::Base
    include ProgrammeHelper

    NOT_AVAILABLE = 'Not available'
    YET_TO_BE_REPORTED = 'Yet to be reported by the lead provider'
    DELIVERY_PARTNER_CHANGE_HINT = 'To change the delivery partner, you must contact the lead provider'

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
      summary_list_row('Training programme', training_programme_display_name)
    end

    def lead_provider_row
      summary_list_row('Lead provider', lead_provider_display_text)
    end

    def delivery_partner_row
      summary_list_row('Delivery partner', delivery_partner_display_text)
    end

    def summary_list_row(key, value)
      { key: { text: key }, value: { text: value } }
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
        tag.span(status_text, class: 'govuk-hint')
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
      TRAINING_PROGRAMME.fetch(training_period.training_programme, 'Unknown')
    end
  end
end
