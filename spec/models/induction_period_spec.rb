RSpec.describe InductionPeriod do
  it { is_expected.to be_a_kind_of(Interval) }
  it { is_expected.to be_a_kind_of(SharedInductionPeriodValidation) }

  it_behaves_like "an induction period"

  describe "enums" do
    it "uses the outcome enum" do
      expect(subject).to define_enum_for(:outcome)
                          .with_values({ fail: "fail", pass: "pass" })
                          .validating(allowing_nil: true)
                          .with_suffix
                          .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to belong_to(:teacher) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:induction_period) }

    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    it { is_expected.to validate_presence_of(:started_on).with_message("Enter a start date") }
    it { is_expected.to validate_presence_of(:appropriate_body_id).with_message("Select an appropriate body") }

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another induction period" }
      let(:finished_on_message) { "End date cannot overlap another induction period" }
      let(:teacher) { FactoryBot.create(:teacher) }

      describe "#teacher_distinct_period" do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            before do
              FactoryBot.create(:induction_period, teacher:,
                                                   started_on: test.existing_period_range.first,
                                                   finished_on: test.existing_period_range.last)
              period.valid?
            end

            let(:period) do
              FactoryBot.build(:induction_period, teacher:,
                                                  started_on: test.new_period_range.first,
                                                  finished_on: test.new_period_range.last)
            end

            let(:messages) { period.errors.messages }

            it "is #{test.expected_valid ? 'valid' : 'invalid'}" do
              if test.expected_valid
                expect(messages).not_to have_key(:started_on)
                expect(messages).not_to have_key(:finished_on)
              else
                case index
                when 0
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 1
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 2
                  expect(messages).not_to have_key(:started_on)
                  expect(messages[:finished_on]).to include(finished_on_message)
                end
              end
            end
          end
        end
      end
    end

    describe "check constraints" do
      subject { FactoryBot.build(:induction_period, teacher:, appropriate_body:, started_on: Date.current, finished_on: Date.current) }

      let(:teacher) { FactoryBot.create(:teacher) }
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

      it "prevents 0 day periods from being written to the database" do
        expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
      end
    end

    describe "declarative updates" do
      let(:instance) { FactoryBot.create(:induction_period, :pass) }

      context "target teacher" do
        let(:target) { instance.teacher }

        it_behaves_like "a declarative touch model", when_changing: %i[started_on finished_on], timestamp_attribute: :api_updated_at, conditional_method: :touch_teacher?

        it_behaves_like "a declarative metadata model",
                        on_event: %i[create destroy update],
                        when_changing: %i[outcome]
      end

      describe "#touch_teacher?" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body:, started_on: "2019-01-01", finished_on: "2019-07-01") }

        context "when a new induction period is created" do
          it "returns true if it is the first induction period for the teacher" do
            expect(induction_period.send(:touch_teacher?)).to be(true)
          end

          it "returns false if it is not the first induction period and outcome has not changed" do
            second_induction_period = FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: "2023-01-01")

            expect(second_induction_period.send(:touch_teacher?)).to be(false)
          end

          it "returns true if it is not the first induction period but outcome is set on creation" do
            second_induction_period = FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: "2023-01-01", outcome: "pass")

            expect(second_induction_period.send(:touch_teacher?)).to be(true)
          end
        end

        context "when an existing induction period is updated" do
          it "returns true if the outcome is changed" do
            induction_period.update!(outcome: "fail")

            expect(induction_period.send(:touch_teacher?)).to be(true)
          end

          it "returns false if the outcome is not changed" do
            induction_period.update!(started_on: "2018-01-01")

            expect(induction_period.send(:touch_teacher?)).to be(false)
          end
        end
      end
    end

    describe "#induction_programme" do
      it { is_expected.to validate_inclusion_of(:induction_programme).in_array(%w[fip cip diy unknown pre_september_2021]).with_message("Choose an induction programme") }
    end

    describe "#training_programme" do
      it { is_expected.to validate_inclusion_of(:training_programme).in_array(%w[provider_led school_led]).with_message("Choose an induction programme") }

      context "when the induction pre-dates School-led and Provider-Led programme types and training_programme is blank" do
        subject { FactoryBot.create(:induction_period, :ongoing, :pre_2021, :legacy_programme_type) }

        it { is_expected.to be_valid }
      end
    end

    describe "#outcome" do
      subject { FactoryBot.build(:induction_period) }

      it { is_expected.to allow_value("pass").for(:outcome) }
      it { is_expected.to allow_value("fail").for(:outcome) }
      it { is_expected.to allow_value(nil).for(:outcome) }
      it { is_expected.not_to allow_value("invalid").for(:outcome) }

      context "when an invalid outcome is provided" do
        before { subject.outcome = "invalid" }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors[:outcome]).to include("Outcome must be either pass or fail")
        end
      end
    end

    describe "#started_on_not_in_future" do
      subject { FactoryBot.build(:induction_period, :ongoing, appropriate_body:, started_on:) }

      context "when started_on is today" do
        let(:started_on) { Date.current }

        it { is_expected.to be_valid }
      end

      context "when started_on is in the past" do
        let(:started_on) { Date.current - 1.day }

        it { is_expected.to be_valid }
      end

      context "when started_on is in the future" do
        let(:started_on) { Date.current + 1.day }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors[:started_on]).to include("Start date cannot be in the future")
        end
      end
    end

    describe "#finished_on_not_in_future" do
      subject { FactoryBot.build(:induction_period, appropriate_body:, finished_on:) }

      context "when finished_on is today" do
        let(:finished_on) { Date.current }

        it { is_expected.to be_valid }
      end

      context "when finished_on is in the past" do
        let(:finished_on) { Date.current - 1.day }

        it { is_expected.to be_valid }
      end

      context "when finished_on is in the future" do
        let(:finished_on) { Date.current + 1.day }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors[:finished_on]).to include("End date cannot be in the future")
        end
      end
    end

    describe "#number_of_terms" do
      context "when finished_on is empty" do
        subject { FactoryBot.build(:induction_period, :ongoing, appropriate_body:) }

        it { is_expected.not_to validate_presence_of(:number_of_terms) }
      end

      context "when finished_on is present" do
        subject { FactoryBot.build(:induction_period, appropriate_body:) }

        it { is_expected.to validate_presence_of(:number_of_terms).with_message("Enter a number of terms") }
      end

      context "when finished on is empty and number of terms is present" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: 3, finished_on: nil) }

        it { is_expected.to validate_absence_of(:number_of_terms).with_message("Delete the number of terms if the induction has no end date") }
      end

      context "when number_of_terms contains non-numeric characters" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: "4.r5", finished_on: Date.current) }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors[:number_of_terms]).to include("Number of terms must be a number with up to 1 decimal place")
        end
      end

      context "when number_of_terms has more than 1 decimal place" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: 3.45, finished_on: Date.current) }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors[:number_of_terms]).to include("Terms can only have up to 1 decimal place")
        end
      end

      context "when number_of_terms has 1 decimal place" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: 3.5, finished_on: Date.current) }

        it { is_expected.to be_valid }
      end

      context "when number_of_terms is an integer" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: 3, finished_on: Date.current) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#training_programme=" do
    subject { FactoryBot.build(:induction_period, appropriate_body_id: 1) }

    it "assigns the induction_programme for provider_led and is valid" do
      subject.induction_programme = nil
      subject.training_programme = "provider_led"

      expect(subject.induction_programme).to eq("fip")
      expect(subject).to be_valid
    end

    it "assigns the induction_programme for school_led and is valid" do
      subject.induction_programme = nil
      subject.training_programme = "school_led"

      expect(subject.induction_programme).to eq("unknown")
      expect(subject).to be_valid
    end
  end

  describe "scopes" do
    describe ".for_teacher" do
      it "returns induction periods only for the specified ect at school period" do
        expect(InductionPeriod.for_teacher(123).to_sql).to end_with(%(WHERE "induction_periods"."teacher_id" = 123))
      end
    end

    describe ".for_appropriate_body" do
      it "returns induction periods only for the specified appropriate_body" do
        expect(InductionPeriod.for_appropriate_body(456).to_sql).to end_with(%( WHERE "induction_periods"."appropriate_body_id" = 456))
      end
    end
  end

  describe "#siblings" do
    subject { induction_period_1.siblings }

    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:induction_period_1) { FactoryBot.create(:induction_period, teacher:, started_on: "2022-01-01", finished_on: "2022-06-01") }
    let!(:induction_period_2) { FactoryBot.create(:induction_period, teacher:, started_on: "2022-06-01", finished_on: "2023-01-01") }
    let!(:unrelated_induction_period) { FactoryBot.create(:induction_period, started_on: "2022-06-01", finished_on: "2023-01-01") }

    it "only returns records that belong to the same mentee" do
      expect(subject).to include(induction_period_2)
    end

    it "doesn't include itself" do
      expect(subject).not_to include(induction_period_1)
    end

    it "doesn't include periods that belong to other mentees" do
      expect(subject).not_to include(unrelated_induction_period)
    end

    context "with completed siblings and nil finished_on and inserting after them" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:previous_period) do
        FactoryBot.create(:induction_period, :pre_2021,
                          teacher:,
                          started_on: "2017-09-11",
                          finished_on: "2018-03-23")
      end

      let!(:next_period) do
        FactoryBot.create(:induction_period, :pre_2021,
                          teacher:,
                          started_on: "2019-01-07",
                          finished_on: "2019-07-16")
      end

      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing,
                          teacher:,
                          started_on: "2025-01-01")
      end

      let(:params) { { started_on: "2025-02-24" } }

      it "allows the edit" do
        expect { induction_period.update!(params) }.not_to raise_error
        expect(induction_period.reload.started_on).to eq(Date.parse("2025-02-24"))
      end
    end

    context "with completed siblings and nil finished_on and inserting between them" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:previous_period) do
        FactoryBot.create(:induction_period, :pre_2021,
                          teacher:,
                          started_on: "2017-09-01",
                          finished_on: "2018-03-01")
      end

      let!(:next_period) do
        FactoryBot.create(:induction_period, :pre_2021,
                          teacher:,
                          started_on: "2019-01-01",
                          finished_on: "2019-07-01")
      end

      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing,
                          teacher:,
                          started_on: "2025-01-01")
      end

      let(:params) { { started_on: "2019-04-24" } }

      it "does not allow the edit" do
        expect { induction_period.update!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
