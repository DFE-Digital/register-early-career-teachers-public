RSpec.describe Migration::ECF2MigratedCombinationsExporter do
  subject(:exporter) { described_class.new }

  let!(:combination_1) do
    FactoryBot.create(:data_migration_teacher_combination,
                      ecf1_ect_profile_id: "7bca2c60-8d8f-49df-9f24-e17d2ff96a0a",
                      ecf1_mentor_profile_id: "ea7fa384-eb7a-4833-b3bc-6e71410dd082",
                      ecf1_ect_combinations: [
                        "<8aa33fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>",
                        "<44433fa7-6a9f-4291-1111-5f9170355871: 222222: 2023: Lead provider B>"
                      ],
                      ecf2_ect_combinations: [
                        "<8aa33fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>"
                      ],
                      ecf1_mentor_combinations: [
                        "<8a234fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>",
                        "<23232323-6a9f-4291-1111-5f9170355871: 222222: 2023: Lead provider B>"
                      ],
                      ecf2_mentor_combinations: [])
  end

  describe "#generate" do
    let!(:csv_output) { exporter.generate_csv }
    let(:csv_data) do
      <<~CSV
        participant_profile_type,ecf1_participant_profile_id,school_urn,cohort_year,lead_provider_name,induction_record_id
        ect,7bca2c60-8d8f-49df-9f24-e17d2ff96a0a,222222,2049,Lead provider A,8aa33fa7-6a9f-4291-9da5-5f9170355871
      CSV
    end

    it "creates a CSV dataset as a string" do
      expect(csv_output).to be_a String
    end

    it "has the correct headers" do
      headers = exporter.send(:csv_headers)

      csv = CSV.parse(csv_output, headers: true)

      expect(csv.headers).to eq headers
    end

    it "contains all the individual ECF1 combinations" do
      csv = CSV.parse(csv_output, headers: true)
      expect(csv).to eq(CSV.parse(csv_data, headers: true))
    end
  end
end
