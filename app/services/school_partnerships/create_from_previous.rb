module SchoolPartnerships
  class CreateFromPrevious
    include ContractPeriodYearConcern

    # Returns the new SchoolPartnership or nil
    def call(previous_school_partnership_id:, school:, author:, current_contract_period_year:)
      return nil unless valid_params?(previous_school_partnership_id, school, author, current_contract_period_year)

      current_year = to_year(current_contract_period_year)

      previous_school_partnership = find_previous_school_partnership(previous_school_partnership_id)
      return nil unless previous_school_partnership

      previous_lead_provider_delivery_partnership = previous_school_partnership.lead_provider_delivery_partnership
      previous_active_lead_provider = previous_lead_provider_delivery_partnership&.active_lead_provider
      return nil unless previous_lead_provider_delivery_partnership && previous_active_lead_provider

      previous_lead_provider_id    = previous_active_lead_provider.lead_provider_id
      previous_delivery_partner_id = previous_lead_provider_delivery_partnership.delivery_partner_id

      current_active_lead_provider_id = find_current_active_lead_provider_id(
        lead_provider_id: previous_lead_provider_id,
        year: current_year
      )
      return nil unless current_active_lead_provider_id

      current_lead_provider_delivery_partnership = find_current_lead_provider_delivery_partnership(
        active_lead_provider_id: current_active_lead_provider_id,
        delivery_partner_id: previous_delivery_partner_id
      )
      return nil unless current_lead_provider_delivery_partnership

      create_partnership_and_record_event!(
        author:,
        school:,
        lead_provider_delivery_partnership: current_lead_provider_delivery_partnership,
        previous_school_partnership_id:
      )
    end

  private

    def valid_params?(previous_school_partnership_id, school, author, current_contract_period_year)
      previous_school_partnership_id.present? &&
        school.present? &&
        author.present? &&
        current_contract_period_year.present?
    end

    def find_previous_school_partnership(id)
      SchoolPartnership
        .includes(lead_provider_delivery_partnership: :active_lead_provider)
        .find_by(id:)
    end

    def find_current_active_lead_provider_id(lead_provider_id:, year:)
      ActiveLeadProvider
        .for_lead_provider(lead_provider_id)
        .for_contract_period_year(year)
        .pick(:id)
    end

    def find_current_lead_provider_delivery_partnership(active_lead_provider_id:, delivery_partner_id:)
      LeadProviderDeliveryPartnership.find_by(
        active_lead_provider_id:,
        delivery_partner_id:
      )
    end

    def create_partnership_and_record_event!(author:, school:, lead_provider_delivery_partnership:, previous_school_partnership_id:)
      ActiveRecord::Base.transaction do
        new_school_partnership = SchoolPartnerships::Create
          .new(
            author:,
            school:,
            lead_provider_delivery_partnership:
          )
          .create

        if new_school_partnership&.persisted?
          Events::Record.record_school_partnership_reused_event!(
            author:,
            school_partnership: new_school_partnership,
            previous_school_partnership_id:,
            happened_at: Time.current
          )

          new_school_partnership
        end
      end
    end
  end
end
