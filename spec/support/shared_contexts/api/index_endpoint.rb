RSpec.shared_examples "an index endpoint with filter by registration_period", skip: "endpoint not ready" do
  context "when fitlering by cohort" do
    let(:registration_period_2023) { FactoryBot.create(:registration_period, year: 2023) }
    let(:registration_period_2024) { FactoryBot.create(:registration_period, year: 2024) }
    let(:registration_period_2025) { FactoryBot.create(:registration_period, year: 2025) }

    it "returns resources for the specified cohorts" do
      create_resource(lead_provider: current_lead_provider, registration_period: registration_period_2023)
      create_resource(lead_provider: current_lead_provider, registration_period: registration_period_2024)
      create_resource(lead_provider: current_lead_provider, registration_period: registration_period_2025)

      authenticated_api_get(path, params: { filter: { cohort: "2023,2024" } })

      expect(parsed_response_data.size).to eq(2)
    end

    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, registration_period_start_years: "2023,2024")).and_call_original

      authenticated_api_get(path, params: { filter: { cohort: "2023,2024" } })
    end
  end
end

RSpec.shared_examples "an index endpoint with filter by updated_since", skip: "endpoint not ready" do
  context "when fitlering by updated_since" do
    it "returns resources updated since the specified date" do
      travel_to(2.hours.ago) do
        create_resource(lead_provider: current_lead_provider)
      end
      travel_to(1.minute.ago) do
        create_resource(lead_provider: current_lead_provider)
      end

      authenticated_api_get(path, params: { filter: { updated_since: 1.hour.ago.iso8601 } })

      expect(parsed_response_data.size).to eq(1)
    end

    it "calls the correct query" do
      updated_since = 1.hour.ago.iso8601
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, updated_since: Time.iso8601(updated_since))).and_call_original

      authenticated_api_get(path, params: { filter: { updated_since: } })
    end

    it "returns 400 - bad request for invalid updated_since" do
      authenticated_api_get(path, params: { filter: { updated_since: "invalid" } })

      expect(response.status).to eq 400
      expect(parsed_response_errors).to eq([
        {
          "detail" => "The filter '#/updated_since' must be a valid ISO 8601 date",
          "title" => "Bad request",
        },
      ])
    end
  end
end
