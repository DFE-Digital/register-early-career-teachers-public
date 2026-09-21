RSpec.describe Admin::Teachers::UndoRegistrationWizard::StartStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::UndoRegistrationWizard::Wizard,
      at_school_periods:
    )
  end
  let(:at_school_periods) { [instance_double(ECTAtSchoolPeriod)] }

  describe "#next_step" do
    context "when the teacher has one school period" do
      it "returns the confirm step" do
        expect(step.next_step).to eq(:confirm)
      end
    end

    context "when the teacher has multiple school periods" do
      let(:at_school_periods) { [instance_double(ECTAtSchoolPeriod), instance_double(MentorAtSchoolPeriod)] }

      it "returns the school period selection step" do
        expect(step.next_step).to eq(:select_school_period)
      end
    end
  end
end
