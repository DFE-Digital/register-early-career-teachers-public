module SchoolPartnerships::API
  class Query < SchoolPartnerships::Query
  protected

    def preload_associations(results)
      results.includes(:delivery_partner, :active_lead_provider, school: :gias_school)
    end
  end
end
