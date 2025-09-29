describe Metadata::Teacher do
  include_context "restricts updates to the Metadata namespace", :teacher_metadata

  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
  end

  describe "validations" do
    subject { FactoryBot.create(:teacher_metadata) }

    it { is_expected.to validate_presence_of(:teacher) }

    describe ".first_became_eligible_for_ect_training_at, .first_became_eligible_for_mentor_training_at" do
      context "when not yet set" do
        subject { FactoryBot.create(:teacher_metadata, first_became_eligible_for_ect_training_at: nil, first_became_eligible_for_mentor_training_at: nil) }

        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_ect_training_at) }
        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_mentor_training_at) }
      end

      context "when already set" do
        subject { FactoryBot.create(:teacher_metadata, first_became_eligible_for_ect_training_at: time, first_became_eligible_for_mentor_training_at: time) }

        let(:time) { Time.zone.now }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_ect_training_at) }
        it { is_expected.to allow_value(time).for(:first_became_eligible_for_ect_training_at) }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_mentor_training_at) }
        it { is_expected.to allow_value(time).for(:first_became_eligible_for_mentor_training_at) }
      end
    end
  end
end
