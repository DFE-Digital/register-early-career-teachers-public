RSpec.describe Schools::ECTs::ChangeStartDateWizard::EditStep do
  subject(:current_step) do
    described_class.new(
      wizard:,
      start_date:
    )
  end

  let(:wizard) do
    instance_double(
      Schools::ECTs::ChangeStartDateWizard::Wizard,
      store:,
      ect_at_school_period:
    )
  end

  let(:store) do
    FactoryBot.build(
      :session_repository,
      form_key: :change_start_date_wizard
    )
  end

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      started_on: Date.new(2024, 1, 1)
    )
  end

  let(:start_date) do
    {
      "day" => "1",
      "month" => "9",
      "year" => "2024"
    }
  end

  before do
    allow(wizard).to receive(:valid_step?) do
      current_step.valid?
    end
  end

  describe ".permitted_params" do
    it "permits the start date" do
      expect(described_class.permitted_params)
        .to contain_exactly(:start_date)
    end
  end

  describe "#initialize" do
    context "when a start date is provided" do
      it "uses the provided date" do
        expect(current_step.start_date).to eq(start_date)
      end
    end

    context "when no start date is provided" do
      subject(:current_step) do
        described_class.new(wizard:)
      end

      let(:stored_start_date) do
        {
          "1" => "2024",
          "2" => "10",
          "3" => "1"
        }
      end

      before do
        store.start_date = stored_start_date
      end

      it "uses the date from the wizard store" do
        expect(current_step.start_date).to eq(
          1 => "2024",
          2 => "10",
          3 => "1"
        )
      end
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }
        .to raise_error(NotImplementedError)
    end
  end

  describe "validations" do
    context "when the start date is missing" do
      let(:start_date) { nil }

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(
          current_step.errors.messages_for(:start_date)
        ).to contain_exactly(
          "Enter the date the ECT started or will start teaching at your school"
        )
      end
    end

    context "when the start date is not a valid date" do
      let(:start_date) do
        {
          1 => 2024,
          2 => 2,
          3 => 30
        }
      end

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(
          current_step.errors.messages_for(:start_date)
        ).to contain_exactly(
          "Enter the start date using the correct format, for example, 17 09 1999"
        )
      end
    end

    context "when the start date is valid" do
      it "is valid" do
        expect(current_step).to be_valid
      end
    end

    context "when the date clashes with a previous ECT at-school period" do
      let(:start_date) do
        {
          1 => 2023,
          2 => 8,
          3 => 1
        }
      end

      let(:previous_school) do
        FactoryBot.create(:school)
      end

      let!(:previous_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher: ect_at_school_period.teacher,
          school: previous_school,
          started_on: Date.new(2023, 9, 1),
          finished_on: Date.new(2023, 12, 31)
        )
      end

      let(:validator) do
        instance_double(
          Schools::Validation::PeriodBoundary
        )
      end

      let(:teacher_name) do
        Teachers::Name
          .new(ect_at_school_period.teacher)
          .full_name
      end

      before do
        allow(wizard)
          .to receive(:name_for)
          .and_return(teacher_name)

        allow(Schools::Validation::PeriodBoundary)
          .to receive(:new)
          .with(
            input_period: previous_period,
            input_date: Date.new(2023, 8, 1)
          )
          .and_return(validator)

        allow(validator).to receive_messages(
          valid?: false,
          type: "teaching",
          started_on_formatted: "1 September 2023",
          earliest_valid_input_date_formatted: "2 September 2023"
        )
      end

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(current_step.errors[:start_date]).to include(
          "Our records show that #{teacher_name} started teaching " \
          "at #{previous_school.name} on 1 September 2023. " \
          "Enter a start date after 2 September 2023."
        )
      end
    end

    context "when the start date is more than four months ahead" do
      around do |example|
        travel_to(Date.new(2025, 1, 1)) do
          example.run
        end
      end

      let(:contract_period) do
        FactoryBot.build_stubbed(
          :contract_period,
          enabled: true
        )
      end

      before do
        allow(ContractPeriod)
          .to receive(:containing_date)
          .and_return(contract_period)
      end

      context "when the date is exactly four months ahead" do
        let(:start_date) do
          {
            1 => 2025,
            2 => 5,
            3 => 1
          }
        end

        it "is valid" do
          expect(current_step).to be_valid
        end
      end

      context "when the date is more than four months ahead" do
        let(:start_date) do
          {
            1 => 2025,
            2 => 5,
            3 => 2
          }
        end

        it "is invalid" do
          expect(current_step).not_to be_valid

          expect(current_step.errors[:start_date]).to include(
            "Start date must be before 2 May 2025. " \
            "You cannot register the ECT this far in advance."
          )
        end
      end
    end

    context "when the date is more than four months ahead in an unopened contract period" do
      around do |example|
        travel_to(Date.new(2025, 1, 1)) do
          example.run
        end
      end

      let(:start_date) do
        {
          1 => 2025,
          2 => 9,
          3 => 1
        }
      end

      before do
        FactoryBot.create(
          :contract_period,
          year: 2025,
          enabled: false,
          started_on: Date.new(2025, 6, 1),
          finished_on: Date.new(2026, 5, 31)
        )
      end

      it "does not add the four-month error" do
        expect(current_step).to be_valid
      end
    end
  end

  describe "#save!" do
    context "when the start date is valid" do
      it "stores the normalised date" do
        expect { current_step.save! }
          .to change(store, :start_date)
          .from(nil)
          .to({
            "1" => "2024",
            "2" => "9",
            "3" => "1"
          })
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end

    context "when the start date is invalid" do
      let(:start_date) { nil }

      it "does not store the date" do
        expect { current_step.save! }
          .not_to change(store, :start_date)
      end

      it "is falsey" do
        expect(current_step.save!).to be_falsey
      end
    end
  end

  describe "#next_step" do
    around do |example|
      travel_to(Date.new(2024, 4, 15)) do
        example.run
      end
    end

    context "when the start date is in the past" do
      let(:start_date) do
        {
          1 => 2024,
          2 => 3,
          3 => 1
        }
      end

      before do
        FactoryBot.create(
          :contract_period,
          year: 2023,
          enabled: true,
          started_on: Date.new(2023, 9, 1),
          finished_on: Date.new(2024, 8, 31)
        )
      end

      it "returns check answers" do
        expect(current_step.next_step)
          .to eq(:check_answers)
      end
    end

    context "when the start date is in an enabled future contract period" do
      let(:start_date) do
        {
          1 => 2024,
          2 => 9,
          3 => 1
        }
      end

      before do
        FactoryBot.create(
          :contract_period,
          year: 2024,
          enabled: true,
          started_on: Date.new(2024, 9, 1),
          finished_on: Date.new(2025, 8, 31)
        )
      end

      it "returns check answers" do
        expect(current_step.next_step)
          .to eq(:check_answers)
      end
    end

    context "when the start date is in a future contract period that is not enabled" do
      let(:start_date) do
        {
          1 => 2024,
          2 => 9,
          3 => 1
        }
      end

      before do
        FactoryBot.create(
          :contract_period,
          year: 2024,
          enabled: false,
          started_on: Date.new(2024, 9, 1),
          finished_on: Date.new(2025, 8, 31)
        )
      end

      it "returns cannot use date" do
        expect(current_step.next_step)
          .to eq(:cannot_use_date)
      end
    end

    context "when the start date is not in a contract period" do
      let(:start_date) do
        {
          1 => 2030,
          2 => 9,
          3 => 1
        }
      end

      it "returns cannot use date" do
        expect(current_step.next_step)
          .to eq(:cannot_use_date)
      end
    end
  end
end
