describe Metadata::TeacherLeadProvider do
  include_context "restricts updates to the Metadata namespace", :teacher_lead_provider_metadata

  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:latest_ect_training_period).class_name("TrainingPeriod").optional }
    it { is_expected.to belong_to(:latest_mentor_training_period).class_name("TrainingPeriod").optional }
    it { is_expected.to belong_to(:latest_mentor_contract_period).class_name("ContractPeriod").with_foreign_key(:latest_mentor_contract_period_year).optional }
    it { is_expected.to belong_to(:latest_ect_contract_period).class_name("ContractPeriod").with_foreign_key(:latest_ect_contract_period_year).optional }
  end

  describe "validations" do
    subject(:metadata) { FactoryBot.build(:teacher_lead_provider_metadata) }

    it { is_expected.to validate_presence_of(:teacher) }
    it { is_expected.to validate_presence_of(:lead_provider) }

    describe "latest_ect_training_period/latest_ect_contract_period consistency" do
      subject(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_ect_training_period) }

      it "is not valid if latest_ect_training_period is set without latest_ect_contract_period" do
        metadata.latest_ect_contract_period = nil
        expect(metadata).not_to be_valid
        expect(metadata.errors[:base]).to include("Latest ECT training period and contract period must both be set or both be nil")
      end

      it "is not valid if latest_ect_contract_period_year is set without latest_ect_training_period" do
        metadata.latest_ect_training_period = nil
        expect(metadata).not_to be_valid
        expect(metadata.errors[:base]).to include("Latest ECT training period and contract period must both be set or both be nil")
      end
    end

    describe "latest_mentor_training_period/latest_mentor_training_period_contract_period_year consistency" do
      subject(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_mentor_training_period) }

      it "is not valid if latest_mentor_training_period is set without latest_mentor_contract_period" do
        metadata.latest_mentor_contract_period = nil
        expect(metadata).not_to be_valid
        expect(metadata.errors[:base]).to include("Latest mentor training period and contract period must both be set or both be nil")
      end

      it "is not valid if latest_mentor_contract_period is set without latest_mentor_training_period" do
        metadata.latest_mentor_training_period = nil
        expect(metadata).not_to be_valid
        expect(metadata.errors[:base]).to include("Latest mentor training period and contract period must both be set or both be nil")
      end
    end
  end
end
