RSpec.describe BuildParticipantTransfers do
  subject(:transfers) { described_class.new(participant_profile:).transfers }

  let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
  let(:user_updated_at) { participant_profile.teacher_profile.user.updated_at }
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
    it "returns a hash of all ECF1 lead_provider IDs and updated_at values" do
      expect(transfers.keys.count).to eq Migration::LeadProvider.count
      transfers.each_value do |value|
        expect(value).to eq user_updated_at
      end
    end

    context "when a participant has not left a school" do
      it "returns the user's updated_at for the lead provider's api_transfer_updated_at" do
        expect(transfers.fetch(induction_programme_1.partnership.lead_provider_id)).to eq user_updated_at
      end
    end

    context "when a participant has left a school" do
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
        it "returns the leaving induction record's updated_at for the lead provider's api_transfer_updated_at" do
          expect(transfers.fetch(induction_programme_1.partnership.lead_provider_id)).to eq induction_record_2.updated_at
        end
      end

      context "and has joined another school" do
        let!(:induction_record_3) do
          FactoryBot.create(:migration_induction_record,
                            induction_programme: induction_programme_2,
                            participant_profile:,
                            school_transfer: true,
                            created_at: 2.days.ago,
                            updated_at: 2.days.ago)
        end

        it "returns the leaving induction record's updated_at for the leaving lead provider" do
          expect(transfers.fetch(induction_programme_1.partnership.lead_provider_id)).to eq induction_record_2.updated_at
        end

        it "returns the joining induction record's updated_at for the joining lead provider" do
          expect(transfers.fetch(induction_programme_2.partnership.lead_provider_id)).to eq induction_record_3.updated_at
        end
      end
    end
  end
end
