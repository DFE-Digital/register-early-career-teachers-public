describe Metadata::TeacherLeadProvider do
  include_context "restricts updates to the Metadata namespace", :teacher_lead_provider_metadata

  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:latest_ect_training_period).class_name("TrainingPeriod").optional }
    it { is_expected.to belong_to(:latest_mentor_training_period).class_name("TrainingPeriod").optional }
  end

  describe "validations" do
    subject { FactoryBot.build(:teacher_lead_provider_metadata) }

    it { is_expected.to validate_presence_of(:teacher) }
    it { is_expected.to validate_presence_of(:lead_provider) }
  end
end
