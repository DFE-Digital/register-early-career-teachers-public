RSpec.describe TeachingSchoolHub do
  describe "validations" do
    subject(:teaching_school_hub) do
      FactoryBot.build(:teaching_school_hub)
    end

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
