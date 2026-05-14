RSpec.describe Schools::Mentors::TeacherLeavingWizard::EditStep do
  subject(:step) { described_class.new(wizard:, leaving_on:) }

  let(:wizard) { instance_double(Schools::Mentors::TeacherLeavingWizard::Wizard, store:, mentor_at_school_period:) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: Date.new(2025, 1, 1)) }
  let(:teacher_name) { Teachers::Name.new(mentor_at_school_period.teacher).full_name }
  let(:store) { FactoryBot.build(:session_repository, form_key: :teacher_leaving_wizard) }
  let(:leaving_on) { { "day" => "1", "month" => "3", "year" => "2025" } }

  before do
    allow(wizard).to receive(:valid_step?) { step.valid? }
    allow(wizard).to receive(:name_for).and_return(teacher_name)
  end

  describe "#save!" do
    it "persists the normalised date into the store" do
      expect { step.save! }
        .to change(store, :leaving_on)
        .from(nil)
        .to({ "1" => "2025", "2" => "3", "3" => "1" })
    end

    context "when invalid" do
      let(:leaving_on) { {} }

      it "returns false and does not write to the store" do
        result = step.save!

        expect(result).to be_falsey
        expect(store.leaving_on).to be_nil
      end
    end
  end

  describe "validations" do
    let(:validator) { instance_double(Schools::Validation::PeriodBoundary) }

    around do |example|
      travel_to(Date.new(2025, 1, 1)) { example.run }
    end

    context "when leaving date is not present" do
      let(:leaving_on) { nil }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on].map(&:squish)).to include(
          "Enter the date the teacher left or will be leaving your school"
        )
      end
    end

    context "when leaving date is invalid" do
      let(:leaving_on) { { 1 => 2025, 2 => 2, 3 => 30 } }

      it "is invalid with the correct error message" do
        step.save!

        expect(step).not_to be_valid
        expect(step.errors[:leaving_on].map(&:squish)).to include(
          "Enter the date in the correct format, for example 30 06 2001"
        )
      end
    end

    context "when date is valid" do
      let(:leaving_on) { { 1 => 2025, 2 => 5, 3 => 1 } }

      it { is_expected.to be_valid }
    end

    context "when date is more than 4 months in the future" do
      let(:leaving_on) { { 1 => 2025, 2 => 5, 3 => 2 } }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on]).to include("Enter a date no further than 4 months from today")
      end
    end

    context "when the date clashes with the ect at school period" do
      before do
        allow(Schools::Validation::PeriodBoundary)
          .to receive(:new)
          .and_return(validator)

        allow(validator).to receive_messages(
          valid?: false,
          invalid_period: mentor_at_school_period,
          type: "teaching",
          started_on_formatted: "1 January 2025",
          earliest_valid_input_date_formatted: "2 January 2025"
        )
      end

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on]).to include("Our records show that #{teacher_name} started teaching at your school on 1 January 2025. Enter a date after 2 January 2025.")
      end
    end

    context "when the date clashes with the latest training period" do
      let(:training_period) { FactoryBot.create(:training_period, :ongoing, :for_mentor, mentor_at_school_period:, started_on: Date.new(2024, 12, 31)) }

      before do
        allow(Schools::Validation::PeriodBoundary)
          .to receive(:new)
          .and_return(validator)

        allow(validator).to receive_messages(
          valid?: false,
          invalid_period: training_period,
          type: "their latest training",
          started_on_formatted: "31 December 2024",
          earliest_valid_input_date_formatted: "1 January 2025"
        )
      end

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on]).to include("Our records show that #{teacher_name} started their latest training at your school on 31 December 2024. Enter a date after 1 January 2025.")
      end
    end

    context "when the date does not clash with any periods" do
      before do
        allow(Schools::Validation::PeriodBoundary)
          .to receive(:new)
          .and_return(validator)

        allow(validator).to receive(:valid?).and_return(true)
      end

      it "is valid" do
        expect(step).to be_valid
      end
    end
  end
end
