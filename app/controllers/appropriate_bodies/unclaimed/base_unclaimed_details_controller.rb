module AppropriateBodies
  module Unclaimed
    # Abstract base for the unclaimed ECT detail pages (claimable, no QTS, claimed by another AB).
    # Subclasses must implement #initial_ect_at_school_periods.
    class BaseUnclaimedDetailsController < AppropriateBodiesController
      layout "full", only: :index

      def index
        @query = params[:q]
        @pagy, @ect_at_school_periods = pagy(filtered_ect_at_school_periods(@query), limit: 50)
      end

    private

      def filtered_ect_at_school_periods(query_string)
        ECTAtSchoolPeriods::TextSearch.new(initial_ect_at_school_periods, query_string:).search
      end

      def initial_ect_at_school_periods
        raise NotImplementedError
      end
    end
  end
end
