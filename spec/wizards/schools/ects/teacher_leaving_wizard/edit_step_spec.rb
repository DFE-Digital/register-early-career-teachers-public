RSpec.describe Schools::ECTs::TeacherLeavingWizard::EditStep do
  subject(:step) { described_class.new(wizard:, leaving_on:) }

  let(:wizard) { instance_double(Schools::ECTs::TeacherLeavingWizard::Wizard, store:, ect_at_school_period:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: Date.new(2025, 1, 1)) }
  let(:teacher_name) { Teachers::Name.new(ect_at_school_period.teacher).full_name }
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
    around do |example|
      travel_to(Date.new(2025, 1, 1)) { example.run }
    end

    context "when date is more than 4 months in the future" do
      let(:leaving_on) { { 1 => 2025, 2 => 5, 3 => 2 } }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on]).to include("Enter a date no further than 4 months from today")
      end
    end

    context "when date is valid" do
      let(:leaving_on) { { 1 => 2025, 2 => 5, 3 => 1 } }

      it { is_expected.to be_valid }
    end

    context "when leaving date is before the start date" do
      let(:leaving_on) { { 1 => 2024, 2 => 12, 3 => 31 } }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on].map(&:squish)).to include(
          "Our records show that #{teacher_name} started teaching at your school on 1 January 2025. Enter a later date."
        )
      end
    end

    context "when leaving date is the same as the start date" do
      let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 1 } }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on].map(&:squish)).to include(
          "Our records show that #{teacher_name} started teaching at your school on 1 January 2025. Enter a later date."
        )
      end

      context "when there is also training period that started after the leaving date" do
        let!(:training_period) do
          FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: Date.new(2025, 1, 1))
        end

        it "is invalid with an error message about the start date" do
          expect(step).not_to be_valid
          expect(step.errors[:leaving_on].map(&:squish)).to include(
            "Our records show that #{teacher_name} started teaching at your school on 1 January 2025. Enter a later date."
          )
        end
      end
    end

    describe "leave date must be after previous training period started_on date" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 1)) }
      let(:leaving_on) { { 1 => 2024, 2 => 12, 3 => 30 } }
      let!(:training_period) do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, started_on: training_period_started_on)
      end

      context "when the previous training_period started in the past" do
        let(:training_period_started_on) { Date.new(2024, 12, 31) }

        context "when the leave date is before the training period started_on date" do
          let(:leaving_on) { { 1 => 2024, 2 => 12, 3 => 30 } }

          it "is invalid with the correct error message" do
            expect(step).not_to be_valid
            expect(step.errors[:leaving_on].map(&:squish)).to include(
              "Our records show that #{teacher_name} started their latest training at your school on 31 December 2024. Enter a later date."
            )
          end
        end

        context "when the leave date is the same as the training period started_on date" do
          let(:leaving_on) { { 1 => 2024, 2 => 12, 3 => 31 } }

          it "is invalid with the correct error message" do
            expect(step).not_to be_valid
            expect(step.errors[:leaving_on].map(&:squish)).to include(
              "Our records show that #{teacher_name} started their latest training at your school on 31 December 2024. Enter a later date."
            )
          end
        end

        context "when the leave date is after the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 1 } }

          it { is_expected.to be_valid }
        end
      end

      context "when the previous training_period started today" do
        let(:training_period_started_on) { Date.new(2025, 1, 1) }

        context "when the leave date is before the training period started_on date" do
          let(:leaving_on) { { 1 => 2024, 2 => 12, 3 => 31 } }

          it { is_expected.to be_valid }
        end

        context "when the leave date is the same as the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 1 } }

          it { is_expected.to be_valid }
        end

        context "when the leave date is after the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 2 } }

          it { is_expected.to be_valid }
        end
      end

      context "when the previous training_period started in the future" do
        let(:training_period_started_on) { Date.new(2025, 1, 2) }

        context "when the leave date is before the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 1 } }

          it { is_expected.to be_valid }
        end

        context "when the leave date is the same as the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 2 } }

          it { is_expected.to be_valid }
        end

        context "when the leave date is after the training period started_on date" do
          let(:leaving_on) { { 1 => 2025, 2 => 1, 3 => 3 } }

          it { is_expected.to be_valid }
        end
      end
    end

    context "when leaving date is invalid" do
      let(:leaving_on) { { 1 => 2025, 2 => 2, 3 => 30 } }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:leaving_on].map(&:squish)).to include(
          "Enter the date in the correct format, for example 30 06 2001"
        )
      end
    end
  end
end
