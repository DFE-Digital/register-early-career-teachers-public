module API
  module V3
    class ParticipantsController < APIController
      def index
        lead_provider = LeadProvider.find_by(name: "Ambition Institute")
        results = {}

        results["no filters"] = Benchmark.measure do
          API::Teachers::Query.new.teachers { paginate(it) }.to_a
        end

        results["lead provider filtering"] = Benchmark.measure do
          API::Teachers::Query.new(lead_provider_id: lead_provider.id).teachers { paginate(it) }.to_a
        end

        results["contract period filtering"] = Benchmark.measure do
          API::Teachers::Query.new(contract_period_years: [2022, 2023]).teachers { paginate(it) }.to_a
        end

        results["updated since filtering"] = Benchmark.measure do
          API::Teachers::Query.new(updated_since: 1.year.ago).teachers { paginate(it) }.to_a
        end

        render json: results.to_json
      end

      def show = head(:method_not_allowed)
      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def resume = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)
    end
  end
end
