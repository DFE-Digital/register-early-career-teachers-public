describe Metadata::Teacher do
  include_context "restricts updates to the Metadata namespace", :teacher_metadata

  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
  end

  describe "validations" do
    subject { FactoryBot.create(:teacher_metadata) }

    it { is_expected.to validate_presence_of(:teacher) }
    it { is_expected.to validate_uniqueness_of(:teacher_id) }

    context "when induction_started_on is present" do
      it { is_expected.to validate_comparison_of(:induction_finished_on).is_greater_than(:induction_started_on).allow_nil }
    end

    context "when induction_finished_on is present" do
      subject { FactoryBot.build(:teacher_metadata, induction_finished_on: 1.day.ago) }

      it { is_expected.to validate_presence_of(:induction_started_on) }
    end
  end
end
