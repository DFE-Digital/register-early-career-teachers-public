module Schools
  class DecoratedMentor < SimpleDelegator
    NOT_CONFIRMED = 'Not confirmed'

    def previous_registration_summary_rows
      [
        {
          key: { text: 'School name' },
          value: { text: previous_school_name },
        },
        {
          key: { text: 'Lead provider' },
          value: { text: previous_lead_provider_name },
        },
        *delivery_partner_row_if_needed,
      ]
    end

    def previous_school_name
      latest_registration_choice&.school&.name || NOT_CONFIRMED
    end

    def previous_lead_provider_name
      previous_confirmed_training_period&.lead_provider_name || NOT_CONFIRMED
    end

    def previous_delivery_partner_name
      previous_confirmed_training_period&.delivery_partner_name || NOT_CONFIRMED
    end

  private

    def delivery_partner_row_if_needed
      return [] unless previous_provider_led?

      [{
        key: { text: 'Delivery partner' },
        value: { text: previous_delivery_partner_name },
      }]
    end
  end
end
