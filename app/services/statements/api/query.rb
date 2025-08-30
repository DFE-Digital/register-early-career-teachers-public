module Statements::API
  class Query < Statements::Query
  protected

    def preload_associations(results)
      results
        .strict_loading
        .includes(:active_lead_provider)
    end
  end
end
