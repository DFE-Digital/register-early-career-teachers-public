describe TrainingPeriod do
  describe "associations" do
    it { is_expected.to belong_to(:ect_at_school_period).class_name("ECTAtSchoolPeriod").inverse_of(:training_periods) }
    it { is_expected.to belong_to(:mentor_at_school_period).inverse_of(:training_periods) }
    it { is_expected.to belong_to(:school_partnership) }
    it { is_expected.to belong_to(:expression_of_interest).class_name('ActiveLeadProvider') }
    it { is_expected.to have_many(:declarations).inverse_of(:training_period) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_partnership_id) }

    context "exactly one id of trainee present" do
      context "when ect_at_school_period_id and mentor_at_school_period_id are all nil" do
        subject do
          FactoryBot.build(:training_period, ect_at_school_period_id: nil, mentor_at_school_period_id: nil)
        end

        it "add an error" do
          subject.valid?
          expect(subject.errors.messages[:base]).to include("Id of trainee missing")
        end
      end

      context "when ect_at_school_period_id and mentor_at_school_period_id are all set" do
        subject do
          FactoryBot.build(:training_period, ect_at_school_period_id: 200, mentor_at_school_period_id: 300)
        end

        it "add an error" do
          subject.valid?
          expect(subject.errors.messages).to include(base: ["Only one id of trainee required. Two given"])
        end
      end
    end

    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another Trainee period' }
      let(:finished_on_message) { 'End date cannot overlap another Trainee period' }

      context 'with mentee' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            let(:ect_at_school_period) do
              FactoryBot.create(:ect_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end
            let(:period) do
              FactoryBot.build(:training_period, ect_at_school_period:,
                                                 started_on: test.new_period_range.first,
                                                 finished_on: test.new_period_range.last)
            end
            let(:messages) { period.errors.messages }

            before do
              FactoryBot.create(:training_period, ect_at_school_period:,
                                                  started_on: test.existing_period_range.first,
                                                  finished_on: test.existing_period_range.last)
              period.valid?
            end

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

      context 'with mentor' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            let(:mentor_at_school_period) do
              FactoryBot.create(:mentor_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end
            let(:period) do
              FactoryBot.build(:training_period, :for_mentor, mentor_at_school_period:,
                                                              started_on: test.new_period_range.first,
                                                              finished_on: test.new_period_range.last)
            end
            let(:messages) { period.errors.messages }

            before do
              FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:,
                                                               started_on: test.existing_period_range.first,
                                                               finished_on: test.existing_period_range.last)
              period.valid?
            end

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
  end

  describe "scopes" do
    describe ".for_ect" do
      it "returns training periods only for the specified ect at school period" do
        expect(TrainingPeriod.for_ect(123).to_sql).to end_with(%(WHERE "training_periods"."ect_at_school_period_id" = 123))
      end
    end

    describe ".for_mentor" do
      it "returns training periods only for the specified mentor at school period" do
        expect(TrainingPeriod.for_mentor(456).to_sql).to end_with(%(WHERE "training_periods"."mentor_at_school_period_id" = 456))
      end
    end
  end

  describe "#siblings" do
    subject { training_period_1.siblings }

    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: '2021-01-01') }
    let!(:training_period_1) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: '2022-01-01', finished_on: '2022-06-01') }
    let!(:training_period_2) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: '2022-06-01', finished_on: '2023-01-01') }

    let!(:unrelated_ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :active, started_on: '2021-01-01')
    end

    let!(:unrelated_training_period) do
      FactoryBot.create(:training_period, ect_at_school_period: unrelated_ect_at_school_period, started_on: '2022-06-01', finished_on: '2023-01-01')
    end

    it "only returns records that belong to the same trainee" do
      expect(subject).to include(training_period_2)
    end

    it "doesn't include itself" do
      expect(subject).not_to include(training_period_1)
    end

    it "doesn't include periods that belong to other trainee" do
      expect(subject).not_to include(unrelated_training_period)
    end
  end
end
