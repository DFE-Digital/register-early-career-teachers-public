RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::SelectPartnershipStep do
  subject(:step) { described_class.new(wizard:, school_partnership_id:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard,
      store:,
      school_partnerships:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:available_school_partnership) { FactoryBot.create(:school_partnership) }
  let(:other_school_partnership) { FactoryBot.create(:school_partnership) }
  let(:school_partnerships) { SchoolPartnership.where(id: available_school_partnership.id) }
  let(:school_partnership_id) { available_school_partnership.id }

  before do
    allow(wizard).to receive(:valid_step?) { step.valid? }
    allow(wizard).to receive(:step_params)
      .and_return(ActionController::Parameters.new(school_partnership_id:).permit(:school_partnership_id))
  end

  describe "#save!" do
    it "stores the selected partnership" do
      expect { step.save! }
        .to change(store, :school_partnership_id)
        .from(nil)
        .to(available_school_partnership.id)
    end

    context "when invalid" do
      let(:school_partnership_id) { nil }

      it "returns false without changing the stored selection" do
        result = step.save!

        expect(result).to be_falsey
        expect(store.school_partnership_id).to be_nil
      end
    end
  end

  describe "validations" do
    context "when partnership is not present" do
      let(:school_partnership_id) { nil }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:school_partnership_id].map(&:squish)).to include("Select a partnership")
      end
    end

    context "when partnership is not available" do
      let(:school_partnership_id) { other_school_partnership.id }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:school_partnership_id].map(&:squish)).to include("Select a partnership")
      end
    end

    context "when partnership is available" do
      it { is_expected.to be_valid }
    end
  end
end
