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
      let(:appropriate_body_period_1) { FactoryBot.create(:appropriate_body, :national) }
      let(:appropriate_body_period_2) { FactoryBot.build(:appropriate_body, :national) }

      it "cannot be reassigned" do
        appropriate_body_period_1.update!(national_body:)
        expect(national_body.appropriate_body_period).to eq(appropriate_body_period_1)

        expect {
          appropriate_body_period_2.update!(national_body:)
        }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: A National Body can only have a single Appropriate Body period")

        expect(national_body.reload.appropriate_body_period.id).to eq(appropriate_body_period_1.id)
      end
    end
  end
end
