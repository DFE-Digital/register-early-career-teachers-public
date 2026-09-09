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
    FactoryBot.create(:ect_at_school_period, :unfinished)
  end

  let(:start_date_as_date) do
    ect_at_school_period.started_on.next_day
  end

  let(:start_date) do
    date_as_hash(start_date_as_date)
  end

  let(:teacher_name) do
    Teachers::Name
      .new(ect_at_school_period.teacher)
      .full_name
  end

  before do
    allow(wizard).to receive(:valid_step?) do
      current_step.valid?
    end

    allow(wizard).to receive(:name_for) do |teacher|
      Teachers::Name.new(teacher).full_name
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

    context "when a new start date and a stored start date are provided" do
      let(:stored_start_date) do
        stored_date_as_hash(
          ect_at_school_period.started_on.next_month
        )
      end

      before do
        store.start_date = stored_start_date
      end

      it "uses the newly provided date" do
        expect(current_step.start_date).to eq(start_date)
      end
    end

    context "when no start date is provided" do
      subject(:current_step) do
        described_class.new(wizard:)
      end

      let(:stored_start_date_as_date) do
        ect_at_school_period.started_on.next_month
      end

      before do
        store.start_date =
          stored_date_as_hash(stored_start_date_as_date)
      end

      it "uses the date from the wizard store" do
        expect(current_step.start_date).to eq(
          date_as_hash(stored_start_date_as_date)
            .transform_values(&:to_s)
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
          "Enter #{teacher_name}'s ECT start date"
        )
      end
    end

    context "when the start date is not a valid date" do
      let(:start_date) do
        {
          1 => Date.current.year,
          2 => 2,
          3 => 30
        }
      end

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(
          current_step.errors.messages_for(:start_date)
        ).to contain_exactly(
          "ECT Start date must be a valid date"
        )
      end
    end

    context "when there is an earliest permitted registration date" do
      let(:earliest_permitted_start_date) do
        ect_at_school_period.started_on.next_day
      end

      before do
        allow(ContractPeriod)
          .to receive(:earliest_permitted_start_date)
          .and_return(earliest_permitted_start_date)
      end

      context "when the start date is before the earliest permitted date" do
        let(:start_date_as_date) do
          earliest_permitted_start_date.prev_day
        end

        it "is invalid" do
          expect(current_step).not_to be_valid

          expect(current_step.errors[:start_date]).to include(
            "#{teacher_name}'s ECT start date must be on or after " \
            "the start of the registration period, " \
            "#{earliest_permitted_start_date.to_fs(:govuk)}."
          )
        end
      end

      context "when the start date equals the earliest permitted date" do
        let(:start_date_as_date) do
          earliest_permitted_start_date
        end

        it "is valid" do
          expect(current_step).to be_valid
        end
      end
    end

    context "when the start date is valid" do
      it "is valid" do
        expect(current_step).to be_valid
      end
    end

    context "when the ECT has a leaving date" do
      let(:leaving_date) do
        Date.current.next_month
      end

      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          finished_on: leaving_date
        )
      end

      context "when the new start date is before the leaving date" do
        let(:start_date_as_date) do
          leaving_date.prev_day
        end

        it "is valid" do
          expect(current_step).to be_valid
        end
      end

      context "when the new start date equals the leaving date" do
        let(:start_date_as_date) do
          leaving_date
        end

        it "is valid" do
          expect(current_step).to be_valid
        end
      end

      context "when the new start date is after the leaving date" do
        let(:start_date_as_date) do
          leaving_date.next_day
        end

        it "is invalid" do
          expect(current_step).not_to be_valid

          expect(current_step.errors[:start_date]).to include(
            "#{teacher_name}'s ECT start date must be on or before " \
            "their leaving date, #{leaving_date.to_fs(:govuk)}"
          )
        end
      end
    end

    context "when the start date is unchanged" do
      let(:start_date_as_date) do
        ect_at_school_period.started_on
      end

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(current_step.errors[:start_date]).to include(
          "The school start date must be different from the current school start date"
        )
      end
    end

    context "when the date clashes with a previous ECT at-school period" do
      let(:teacher) do
        FactoryBot.create(:teacher)
      end

      let(:previous_school) do
        FactoryBot.create(:school)
      end

      let!(:previous_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: previous_school
        )
      end

      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          teacher:,
          started_on: previous_period.finished_on.next_day
        )
      end

      let(:start_date_as_date) do
        previous_period.started_on.prev_day
      end

      let(:earliest_valid_input_date) do
        previous_period.started_on.next_day
      end

      let(:validator) do
        instance_double(
          Schools::Validation::PeriodBoundary
        )
      end

      before do
        allow(Schools::Validation::PeriodBoundary)
          .to receive(:new)
          .with(
            input_period: previous_period,
            input_date: start_date_as_date
          )
          .and_return(validator)

        allow(validator).to receive_messages(
          valid?: false,
          type: "teaching",
          started_on_formatted:
            previous_period.started_on.to_fs(:govuk),
          earliest_valid_input_date_formatted:
            earliest_valid_input_date.to_fs(:govuk)
        )
      end

      it "is invalid" do
        expect(current_step).not_to be_valid

        expect(current_step.errors[:start_date]).to include(
          "Our records show that #{teacher_name} started teaching " \
          "at #{previous_school.name} on " \
          "#{previous_period.started_on.to_fs(:govuk)}. " \
          "Enter a start date after " \
          "#{earliest_valid_input_date.to_fs(:govuk)}."
        )
      end
    end

    context "when the start date is more than four months ahead" do
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
        let(:start_date_as_date) do
          Date.current + 4.months
        end

        it "is valid" do
          expect(current_step).to be_valid
        end
      end

      context "when the date is more than four months ahead" do
        let(:start_date_as_date) do
          Date.current + 4.months + 1.day
        end

        it "is invalid" do
          expect(current_step).not_to be_valid

          expect(current_step.errors[:start_date]).to include(
            "#{teacher_name}'s ECT start date must not be more than " \
            "4 months from today, " \
            "#{(Date.current + 4.months).to_fs(:govuk)}"
          )
        end
      end
    end

    context "when the date is more than four months ahead in an unopened contract period" do
      let!(:contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          enabled: false
        )
      end

      let(:start_date_as_date) do
        [
          contract_period.started_on,
          Date.current + 4.months + 1.day
        ].max
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
          .to(
            date_as_hash(start_date_as_date)
              .transform_keys(&:to_s)
          )
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
    context "when the start date is in the past" do
      let!(:contract_period) do
        FactoryBot.create(
          :contract_period,
          :previous,
          enabled: true
        )
      end

      let(:start_date_as_date) do
        contract_period.started_on
      end

      it "returns check answers" do
        expect(current_step.next_step)
          .to eq(:check_answers)
      end
    end

    context "when the start date is in an enabled future contract period" do
      let!(:contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          enabled: true
        )
      end

      let(:start_date_as_date) do
        contract_period.started_on
      end

      it "returns check answers" do
        expect(current_step.next_step)
          .to eq(:check_answers)
      end
    end

    context "when the start date is in a future contract period that is not enabled" do
      let!(:contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          enabled: false
        )
      end

      let(:start_date_as_date) do
        contract_period.started_on
      end

      it "returns cannot use date" do
        expect(current_step.next_step)
          .to eq(:cannot_use_date)
      end
    end

    context "when the start date is not in a contract period" do
      before do
        allow(ContractPeriod)
          .to receive(:containing_date)
          .and_return(nil)
      end

      it "returns cannot use date" do
        expect(current_step.next_step)
          .to eq(:cannot_use_date)
      end
    end
  end

private

  def date_as_hash(date)
    {
      1 => date.year,
      2 => date.month,
      3 => date.day
    }
  end

  def stored_date_as_hash(date)
    {
      "1" => date.year.to_s,
      "2" => date.month.to_s,
      "3" => date.day.to_s
    }
  end
end
