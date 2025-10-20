module Migration
  class Partnership < Migration::Base
    belongs_to :school
    belongs_to :lead_provider
    belongs_to :delivery_partner
    belongs_to :cohort

    def forbidden?
      ProviderRelationship.where(cohort_id:, lead_provider_id:, delivery_partner_id:).none?
    end
  end
end
