RSpec.describe Admin::Teachers::UndoRegistrationWizard::SelectSchoolPeriodStep do
  subject(:step) { described_class.new(wizard:, school_period_gid:) }

  let(:store) { FactoryBot.build(:session_repository) }
  let(:school_period_gid) { "school-period-gid" }
  let(:selected_school_period) { instance_double(ECTAtSchoolPeriod) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::UndoRegistrationWizard::Wizard,
      store:,
      teacher_name: "Kakashi Hatake",
      school_period_from_gid: selected_school_period
    )
  end

  before do
    allow(wizard).to receive(:valid_step?) { step.valid? }
    allow(wizard).to receive(:step_params)
      .and_return(ActionController::Parameters.new(school_period_gid:).permit(:school_period_gid))
  end

  describe "#save!" do
    it "stores the selected school period" do
      expect { step.save! }
        .to change(store, :school_period_gid)
        .from(nil)
        .to(school_period_gid)
    end

    context "when the school period is invalid" do
      let(:selected_school_period) { nil }

      it "returns false without changing the stored selection" do
        expect(step.save!).to be(false)
        expect(store.school_period_gid).to be_nil
      end
    end
  end

  describe "step navigation" do
    it "returns start as the previous step" do
      expect(step.previous_step).to eq(:start)
    end

    it "returns confirm as the next step" do
      expect(step.next_step).to eq(:confirm)
    end
  end

  describe "validations" do
    context "when a school period has not been selected" do
      let(:school_period_gid) { nil }
      let(:selected_school_period) { nil }

      it "adds the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:school_period_gid])
          .to contain_exactly("Select a school period to undo for Kakashi Hatake")
      end
    end

    context "when a valid school period has been selected" do
      it { is_expected.to be_valid }
    end
  end
end
