RSpec.describe LegacyAppropriateBody, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body_period) }
  end

  describe "validations" do
    subject { FactoryBot.build(:legacy_appropriate_body) }

    it { is_expected.to validate_presence_of(:body_type).with_message("Must be local authority, national or teaching school hub") }
    it { is_expected.to validate_inclusion_of(:body_type).in_array(%i[national teaching_school_hub local_authority]).with_message("Must be local authority, national or teaching school hub") }

    it { is_expected.to validate_presence_of(:dqt_id) }
    it { is_expected.to validate_uniqueness_of(:dqt_id).case_insensitive }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
