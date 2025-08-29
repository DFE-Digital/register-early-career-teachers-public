module Statements::API
  class Query < Statements::Query
  protected

    def preload_associations(results)
      results.includes(:active_lead_provider)
    end
  end
end
