module Schools
  class DecoratedMentor < SimpleDelegator
    NOT_CONFIRMED = "Not confirmed"

    def previous_registration_summary_rows
      rows = [
        {
          key: { text: "School name" },
          value: { text: previous_school_name },
        },
        {
          key: { text: "Lead provider" },
          value: { text: previous_lead_provider_name },
        },
      ]

      if previous_provider_led?
        rows << {
          key: { text: "Delivery partner" },
          value: { text: previous_delivery_partner_name },
        }
      end

      rows
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
  end
end
