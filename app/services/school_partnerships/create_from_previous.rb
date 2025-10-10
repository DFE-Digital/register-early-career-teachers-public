module SchoolPartnerships
  class CreateFromPrevious
    def call(previous_school_partnership_id:, school:, author:, current_contract_period_year:)
      return nil if previous_school_partnership_id.blank? || school.blank? || author.blank? || current_contract_period_year.blank?

      previous_school_partnership = SchoolPartnership
        .includes(lead_provider_delivery_partnership: :active_lead_provider)
        .find_by(id: previous_school_partnership_id)
      return nil unless previous_school_partnership

      previous_lpdp = previous_school_partnership.lead_provider_delivery_partnership
      previous_alp  = previous_lpdp&.active_lead_provider
      return nil unless previous_lpdp && previous_alp

      previous_lead_provider_id    = previous_alp.lead_provider_id
      previous_delivery_partner_id = previous_lpdp.delivery_partner_id

      current_alp_id = ActiveLeadProvider
        .for_lead_provider(previous_lead_provider_id)
        .for_contract_period_year(current_contract_period_year)
        .pick(:id)
      return nil unless current_alp_id

      current_lpdp = LeadProviderDeliveryPartnership.find_by(
        active_lead_provider_id: current_alp_id,
        delivery_partner_id: previous_delivery_partner_id
      )
      return nil unless current_lpdp

      ActiveRecord::Base.transaction do
        new_school_partnership = SchoolPartnerships::Create
          .new(
            author:,
            school:,
            lead_provider_delivery_partnership: current_lpdp
          )
          .create
        return nil unless new_school_partnership&.persisted?

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
