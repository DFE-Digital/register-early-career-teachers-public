RSpec.describe InductionPeriod do
  it { is_expected.to be_a_kind_of(Interval) }
  it { is_expected.to be_a_kind_of(SharedInductionPeriodValidation) }

  it_behaves_like 'an induction period'

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to belong_to(:teacher) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:induction_period) }

    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

    it { is_expected.to validate_presence_of(:appropriate_body_id).with_message("Select an appropriate body") }

    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another induction period' }
      let(:finished_on_message) { 'End date cannot overlap another induction period' }
      let(:teacher) { FactoryBot.create(:teacher) }

      context '#teacher_distinct_period' do
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

    it { is_expected.to validate_inclusion_of(:induction_programme).in_array(%w[fip cip diy unknown pre_september_2021]).with_message("Choose an induction programme") }

    describe "outcome validation" do
      subject { FactoryBot.build(:induction_period) }

      it { is_expected.to allow_value('pass').for(:outcome) }
      it { is_expected.to allow_value('fail').for(:outcome) }
      it { is_expected.to allow_value(nil).for(:outcome) }
      it { is_expected.not_to allow_value('invalid').for(:outcome) }

      context "when an invalid outcome is provided" do
        before { subject.outcome = 'invalid' }

        it do
          is_expected.not_to be_valid
          expect(subject.errors[:outcome]).to include("Outcome must be either pass or fail")
        end
      end
    end

    describe "started_on_not_in_future" do
      subject { FactoryBot.build(:induction_period, :active, appropriate_body:, started_on:) }

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
          is_expected.not_to be_valid
          expect(subject.errors[:started_on]).to include("Start date cannot be in the future")
        end
      end
    end

    describe "finished_on_not_in_future" do
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
          is_expected.not_to be_valid
          expect(subject.errors[:finished_on]).to include("End date cannot be in the future")
        end
      end
    end

    describe "number_of_terms" do
      context "when finished_on is empty" do
        subject { FactoryBot.build(:induction_period, :active, appropriate_body:) }

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
          is_expected.not_to be_valid
          expect(subject.errors[:number_of_terms]).to include("Number of terms must be a number with up to 1 decimal place")
        end
      end

      context "when number_of_terms has more than 1 decimal place" do
        subject { FactoryBot.build(:induction_period, appropriate_body:, number_of_terms: 3.45, finished_on: Date.current) }

        it do
          is_expected.not_to be_valid
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
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:induction_period_1) { FactoryBot.create(:induction_period, teacher:, started_on: '2022-01-01', finished_on: '2022-06-01') }
    let!(:induction_period_2) { FactoryBot.create(:induction_period, teacher:, started_on: '2022-06-01', finished_on: '2023-01-01') }
    let!(:unrelated_induction_period) { FactoryBot.create(:induction_period, started_on: '2022-06-01', finished_on: '2023-01-01') }

    subject { induction_period_1.siblings }

    it "only returns records that belong to the same mentee" do
      is_expected.to include(induction_period_2)
    end

    it "doesn't include itself" do
      is_expected.not_to include(induction_period_1)
    end

    it "doesn't include periods that belong to other mentees" do
      is_expected.not_to include(unrelated_induction_period)
    end
  end
end
