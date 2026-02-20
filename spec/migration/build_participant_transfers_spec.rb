RSpec.describe BuildParticipantTransfers do
  subject(:transfers) { described_class.new(participant_profile:).transfers }

  let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
  let(:induction_programme_1) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let(:induction_programme_2) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let!(:induction_record_1) do
    FactoryBot.create(:migration_induction_record,
                      induction_programme: induction_programme_1,
                      participant_profile:,
                      created_at: 2.years.ago,
                      updated_at: 2.years.ago)
  end

  describe "#transfers" do
    context "when a participant has not left a school" do
      it "returns an empty array" do
        expect(transfers).to eq []
      end
    end

    context "when a participant has left a school but not joined another" do
      let!(:induction_record_2) do
        FactoryBot.create(:migration_induction_record,
                          induction_programme: induction_programme_1,
                          participant_profile:,
                          school_transfer: true,
                          induction_status: "leaving",
                          end_date: 2.weeks.ago,
                          created_at: 2.weeks.ago,
                          updated_at: 2.weeks.ago)
      end

      context "but not joined another school" do
        it "returns the leaving data" do
          training_provider_info = transfers.first[:leaving].training_provider_info

          aggregate_failures "leaving transfer data" do
            expect(transfers.count).to eq 1
            expect(training_provider_info.lead_provider_info.ecf1_id).to eq induction_programme_1.partnership.lead_provider_id
            expect(training_provider_info.delivery_partner_info.ecf1_id).to eq induction_programme_1.partnership.delivery_partner_id
            expect(training_provider_info.cohort_year).to eq induction_programme_1.partnership.cohort.start_year
            expect(transfers.first[:leaving].updated_at).to eq induction_record_2.updated_at
          end
        end

        it "does not return any joining data" do
          expect(transfers.first[:joining]).to be_nil
        end
      end

      context "and joined another school" do
        let!(:induction_record_3) do
          FactoryBot.create(:migration_induction_record,
                            induction_programme: induction_programme_2,
                            participant_profile:,
                            school_transfer: true,
                            created_at: 2.days.ago,
                            updated_at: 2.days.ago)
        end

        it "also returns the joining data" do
          training_provider_info = transfers.first[:joining].training_provider_info

          aggregate_failures "joining transfer data" do
            expect(training_provider_info.lead_provider_info.ecf1_id).to eq induction_programme_2.partnership.lead_provider_id
            expect(training_provider_info.delivery_partner_info.ecf1_id).to eq induction_programme_2.partnership.delivery_partner_id
            expect(training_provider_info.cohort_year).to eq induction_programme_2.partnership.cohort.start_year
            expect(transfers.first[:joining].updated_at).to eq induction_record_3.updated_at
          end
        end
      end
    end
  end
end
