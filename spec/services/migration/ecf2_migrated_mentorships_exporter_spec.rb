RSpec.describe Migration::ECF2MigratedMentorshipsExporter do
  subject(:exporter) { described_class.new }

  let!(:combination_1) do
    FactoryBot.create(:data_migration_teacher_combination,
                      ecf1_ect_profile_id: "7bca2c60-8d8f-49df-9f24-e17d2ff96a0a",
                      ecf1_mentor_profile_id: "ea7fa384-eb7a-4833-b3bc-6e71410dd082",
                      ecf1_mentorships: [
                        "<e491dde6-90c5-473d-b6e2-3b4c63ce90e7: e491dde6-90c5-473d-b6e2-3b4c63ce90e7: ab3d41f5-c42a-4396-80e6-7456f2856253: 2023-02-09: 2023-12-09>",
                        "<f6f40352-9141-4b00-bcb7-c5250b9ecfc8: f6f40352-9141-4b00-bcb7-c5250b9ecfc8: 9246931b-bd85-445f-aea6-8802c124d9d9: 2023-13-09: >"
                      ],
                      ecf2_mentorships: [
                        "<f6f40352-9141-4b00-bcb7-c5250b9ecfc8: f6f40352-9141-4b00-bcb7-c5250b9ecfc8: 9246931b-bd85-445f-aea6-8802c124d9d9: 2023-13-09: >"
                      ])
  end

  describe "#generate" do
    let!(:csv_output) { exporter.generate_csv }
    let(:csv_data) do
      <<~CSV
        ect_participant_profile_id,mentor_participant_profile_id,started_on,finished_on,ecf_start_induction_record_id,ecf_end_induction_record_id
        7bca2c60-8d8f-49df-9f24-e17d2ff96a0a,9246931b-bd85-445f-aea6-8802c124d9d9,2023-13-09,,f6f40352-9141-4b00-bcb7-c5250b9ecfc8,f6f40352-9141-4b00-bcb7-c5250b9ecfc8
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
