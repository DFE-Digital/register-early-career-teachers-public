RSpec.describe BuildParticipantTransfers do
  subject(:transfers) { described_class.new(induction_records:, user_updated_at:).transfers }

  let(:training_provider_1) { FactoryBot.build(:ecf1_teacher_history_training_provider_info) }
  let(:lead_provider_1_ecf_id) { training_provider_1.lead_provider_info.ecf1_id }
  let(:induction_record_1) do
    FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                     training_provider_info: training_provider_1,
                     created_at: 2.years.ago,
                     updated_at: 2.years.ago)
  end
  let(:school_1) { induction_record_1.school }
  let(:induction_records) { [induction_record_1] }
  let(:user_updated_at) { 2.days.ago }

  describe "#transfers" do
    it "returns a hash of all ECF1 lead_provider IDs and updated_at values" do
      expect(transfers.keys).to eq [lead_provider_1_ecf_id]
      transfers.each_value do |value|
        expect(value).to eq user_updated_at
      end
    end

    context "when a participant has not left a school" do
      it "returns the user's updated_at for the lead provider's api_transfer_updated_at" do
        expect(transfers.fetch(lead_provider_1_ecf_id)).to eq user_updated_at
      end
    end

    context "when a participant has left a school" do
      let(:induction_record_2) do
        FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                         training_provider_info: training_provider_1,
                         school: school_1,
                         school_transfer: true,
                         induction_status: "leaving",
                         end_date: 2.weeks.ago,
                         created_at: 2.weeks.ago,
                         updated_at: 2.weeks.ago)
      end

      let(:induction_records) { [induction_record_1, induction_record_2] }

      context "but not joined another school" do
        it "returns the leaving induction record's updated_at for the lead provider's api_transfer_updated_at" do
          expect(transfers.fetch(lead_provider_1_ecf_id)).to eq induction_record_2.updated_at
        end
      end

      context "and has joined another school" do
        let(:training_provider_2) { FactoryBot.build(:ecf1_teacher_history_training_provider_info) }
        let(:lead_provider_2_ecf_id) { training_provider_2.lead_provider_info.ecf1_id }

        let(:induction_record_3) do
          FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                           training_provider_info: training_provider_2,
                           school_transfer: true,
                           created_at: 5.days.ago,
                           updated_at: 5.days.ago)
        end

        let(:induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

        it "returns the leaving induction record's updated_at for the leaving lead provider" do
          expect(transfers.fetch(lead_provider_1_ecf_id)).to eq induction_record_2.updated_at
        end

        it "returns the joining induction record's updated_at for the joining lead provider" do
          expect(transfers.fetch(lead_provider_2_ecf_id)).to eq induction_record_3.updated_at
        end
      end
    end
  end
end
