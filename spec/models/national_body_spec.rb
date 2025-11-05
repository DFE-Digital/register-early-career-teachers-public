RSpec.describe NationalBody, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:dfe_sign_in_organisation) }
    it { is_expected.to have_one(:appropriate_body_period) }
  end

  describe "validations" do
    subject { FactoryBot.build(:national_body) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    describe "#appropriate_body_period" do
      let(:national_body) { FactoryBot.create(:national_body) }
      let(:appropriate_body_period) { FactoryBot.build(:appropriate_body) }
      let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body) }

      it "cannot be reassigned" do
        appropriate_body_period.update!(national_body:)
        expect(national_body.appropriate_body_period).to eq(appropriate_body_period)

        expect {
          other_appropriate_body_period.update!(national_body:)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(national_body.appropriate_body_period).not_to eq(other_appropriate_body_period)
        expect(national_body.appropriate_body_period).to eq(appropriate_body_period)
      end
    end
  end
end
