RSpec.describe Schools::ECTs::TeacherLeavingWizard::CheckAnswersStep do
  subject(:step) { described_class.new(wizard:, leaving_on:) }

  let(:wizard) do
    instance_double(
      Schools::ECTs::TeacherLeavingWizard::Wizard,
      store:,
      ect_at_school_period:,
      author:
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository, form_key: :teacher_leaving_wizard).tap { |repo| repo.leaving_on = leaving_on }
  end

  let(:ect_at_school_period) { FactoryBot.build_stubbed(:ect_at_school_period) }
  let(:author) { instance_double(User) }
  let(:leaving_on) { { "1" => "2025", "2" => "3", "3" => "1" } }

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:edit) }
  end

  describe "#next_step" do
    it { expect(step.next_step).to eq(:confirmation) }
  end

  describe "#leaving_date" do
    it "parses the date when present" do
      expect(step.leaving_date).to eq(Date.new(2025, 3, 1))
    end

    context "when leaving_on is blank" do
      let(:leaving_on) { nil }

      it { expect(step.leaving_date).to be_nil }
    end
  end

  describe "#save!" do
    context "when leaving_on is blank" do
      let(:leaving_on) { nil }

      it "returns false" do
        expect(step.save!).to be_falsey
      end
    end

    context "when leaving_on is present" do
      let(:finish_service) { instance_double(ECTAtSchoolPeriods::Finish, finish!: true) }

      before do
        allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(finish_service)
      end

      it "finishes the ECT at school period" do
        expect(step.save!).to be_truthy
        expect(ECTAtSchoolPeriods::Finish).to have_received(:new)
        expect(finish_service).to have_received(:finish!)
      end
    end
  end
end
