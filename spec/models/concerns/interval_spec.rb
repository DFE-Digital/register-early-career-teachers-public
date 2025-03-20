FakePeriod = Struct.new(:started_on, :finished_on)

describe Interval do
  let(:school_id) { FactoryBot.create(:school, urn: "1234567").id }
  let(:teacher_id) { FactoryBot.create(:teacher, trs_first_name: "Teacher", trs_last_name: "One").id }

  describe "validations" do
    context "period dates" do
      context "when finished_on is earlier than started_on" do
        subject { DummyMentor.new(started_on: Date.yesterday, finished_on: 2.days.ago) }

        before { subject.valid? }

        it "adds an error" do
          expect(subject.errors.messages).to include(finished_on: ["The end date must be later than the start date (#{Date.yesterday.to_fs(:govuk)})"])
        end
      end

      context "when finished_on matches started_on" do
        subject { DummyMentor.new(started_on: Date.yesterday, finished_on: Date.yesterday) }

        before { subject.valid? }

        it "adds an error" do
          expect(subject.errors.messages).to include(finished_on: ["The end date must be later than the start date (#{Date.yesterday.to_fs(:govuk)})"])
        end
      end
    end
  end

  describe "scopes" do
    let!(:teacher_2_id) { FactoryBot.create(:teacher, trs_first_name: "Teacher", trs_last_name: "Two").id }
    let!(:period_1) { DummyMentor.create(teacher_id:, school_id:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { DummyMentor.create(teacher_id:, school_id:, started_on: '2023-07-01', finished_on: '2023-12-01') }
    let!(:period_3) { DummyMentor.create(teacher_id:, school_id:, started_on: '2024-01-01', finished_on: nil) }
    let!(:teacher_2_period) do
      DummyMentor.create(teacher_id: teacher_2_id, school_id:, started_on: '2023-02-01', finished_on: '2023-07-01')
    end

    describe ".overlapping_with" do
      it "returns periods overlapping with the specified date range" do
        expect(DummyMentor.overlapping_with(FakePeriod.new('2023-02-01', '2023-10-01'))).to match_array([period_1, period_2, teacher_2_period])
      end

      it "returns periods starting after the specified start date if end date is nil" do
        expect(DummyMentor.overlapping_with(FakePeriod.new('2024-01-01', nil))).to match_array([period_3])
      end

      it "does not return periods outside the specified date range" do
        expect(DummyMentor.overlapping_with(FakePeriod.new('2022-01-01', '2022-12-31'))).to be_empty
      end
    end

    describe '.ongoing' do
      it 'returns records where the finished_on date is null' do
        expect(DummyMentor.ongoing.to_sql).to end_with(%("finished_on" IS NULL))
      end
    end

    describe ".containing_period" do
      it "returns periods that completely contain the specified period" do
        expect(DummyMentor.containing_period(FakePeriod.new('2023-8-1', '2023-9-1'))).to match_array([period_2])
      end

      it 'returns periods where the finished_on date is null' do
        expect(DummyMentor.containing_period(FakePeriod.new('2024-2-1', '2024-4-23'))).to match_array([period_3])
        expect(DummyMentor.containing_period(FakePeriod.new('2024-5-1', nil))).to match_array([period_3])
      end

      it "does not return periods that do not completely contain the specified date range" do
        expect(DummyMentor.containing_period(FakePeriod.new('2021-09-01', '2023-12-31'))).to be_empty
      end
    end

    describe '.started_before' do
      it 'returns records where the started_on date is earlier than the provided date' do
        expect(DummyMentor.started_before(Date.yesterday).to_sql).to end_with(%("started_on" < '#{Date.yesterday.iso8601}'))
      end
    end

    describe '.started_on_or_after' do
      it 'returns records where the started_on date is equal to or later than the provided date' do
        expect(DummyMentor.started_on_or_after(Date.yesterday).to_sql).to end_with(%("started_on" >= '#{Date.yesterday.iso8601}'))
      end
    end

    describe '.finished_before' do
      it 'returns records where the finished_on date is earlier than the provided date' do
        expect(DummyMentor.finished_before(Date.yesterday).to_sql).to end_with(%("finished_on" < '#{Date.yesterday.iso8601}'))
      end
    end

    describe '.finished_on_or_after' do
      it 'returns records where the finished_on date is equal to or later than the provided date' do
        expect(DummyMentor.finished_on_or_after(Date.yesterday).to_sql).to end_with(%("finished_on" >= '#{Date.yesterday.iso8601}'))
      end
    end
  end

  describe "#finish!" do
    subject(:interval) { DummyInterval.new(started_on: 1.week.ago) }

    context "without finished_on" do
      it "sets the current date as the end date of the interval" do
        expect { interval.finish! }.to change(interval, :finished_on).from(nil).to(Date.current)
      end
    end

    context "with finished_on" do
      it "sets it as the end date of the interval" do
        expect { interval.finish!(Date.yesterday) }.to change(interval, :finished_on).from(nil).to(Date.yesterday)
      end
    end
  end

  describe '#ongoing?' do
    context 'without finished_on' do
      subject(:interval) { DummyInterval.new(started_on: 1.week.ago, finished_on: nil) }

      it { is_expected.to be_ongoing }
    end

    context 'with finished_on' do
      subject(:interval) { DummyInterval.new(started_on: 1.week.ago, finished_on: 1.day.ago) }

      it { is_expected.not_to be_ongoing }
    end
  end

  describe '#has_overlap_with_siblings?' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: nil) }

    context 'with overlapping sibling intervals' do
      before { DummyMentor.create(teacher_id:, school_id:, started_on: Date.yesterday, finished_on: Date.current) }

      it { is_expected.to have_overlap_with_siblings }
    end

    context 'without overlapping sibling intervals' do
      before { DummyMentor.create(teacher_id:, school_id:, started_on: 1.week.ago, finished_on: 5.days.ago) }

      it { is_expected.not_to have_overlap_with_siblings }
    end
  end

  describe '#predecessors' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: nil) }

    context 'with sibling intervals starting earlier' do
      let!(:predecessor) { DummyMentor.create(teacher_id:, school_id:, started_on: 2.weeks.ago, finished_on: 5.days.ago) }

      it 'returns previous intervals' do
        expect(interval.predecessors).to match_array([predecessor])
      end
    end

    context 'without sibling intervals starting earlier' do
      it 'returns no intervals' do
        expect(interval.predecessors).to be_empty
      end
    end
  end

  describe '#has_predecessors?' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: nil) }

    context 'with sibling intervals starting earlier' do
      before { DummyMentor.create(teacher_id:, school_id:, started_on: 2.weeks.ago, finished_on: 5.days.ago) }

      it { is_expected.to have_predecessors }
    end

    context 'without sibling intervals starting earlier' do
      it { is_expected.not_to have_predecessors }
    end
  end

  describe '#siblings' do
    subject { AnotherDummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: nil) }

    it 'raises a NotImplementedError exception' do
      expect { subject.siblings }.to raise_error(NotImplementedError)
    end
  end

  describe '#siblings?' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: nil) }

    context 'with sibling intervals' do
      before { DummyMentor.create(teacher_id:, school_id:, started_on: 2.weeks.ago, finished_on: 5.days.ago) }

      it { is_expected.to have_siblings }
    end

    context 'without sibling intervals' do
      it { is_expected.not_to have_siblings }
    end
  end

  describe '#successors' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: 1.day.ago) }

    context 'when there are sibling intervals starting later' do
      let!(:successor) { DummyMentor.create(teacher_id:, school_id:, started_on: 1.day.ago, finished_on: nil) }

      it 'returns them' do
        expect(interval.successors).to match_array([successor])
      end
    end

    context 'when there are no sibling intervals starting later' do
      it 'returns no intervals' do
        expect(interval.successors).to be_empty
      end
    end
  end

  describe '#has_successors?' do
    subject(:interval) { DummyMentor.new(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: 1.day.ago) }

    context 'with sibling intervals starting later' do
      before { DummyMentor.create(teacher_id:, school_id:, started_on: 1.day.ago, finished_on: nil) }

      it { is_expected.to have_successors }
    end

    context 'without sibling intervals starting later' do
      it { is_expected.not_to have_successors }
    end
  end

  describe '#last_finished_sibling' do
    subject(:second_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 19.days.ago, finished_on: 13.days.ago) }

    context 'with finished siblings' do
      let!(:first_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 30.days.ago, finished_on: 20.days.ago) }
      let!(:third_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 12.days.ago, finished_on: 6.days.ago) }
      let!(:fourth_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 5.days.ago, finished_on: 2.days.ago) }
      let!(:ongoing_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 1.day.ago, finished_on: nil) }

      it 'returns last finished sibling' do
        expect(second_interval.last_finished_sibling.id).to eq(fourth_interval.id)
      end
    end

    context 'without finished siblings' do
      let!(:ongoing_interval) { DummyMentor.create(teacher_id:, school_id:, started_on: 1.day.ago, finished_on: nil) }

      it { expect(second_interval.last_finished_sibling).to be_nil }
    end
  end
end

class DummyMentor < ApplicationRecord
  include Interval

  self.table_name = "mentor_at_school_periods"

  def siblings = self.class.all.excluding(self)
end

class AnotherDummyMentor < ApplicationRecord
  include Interval

  self.table_name = "mentor_at_school_periods"
end

class DummyInterval < OpenStruct
  def self.scope(*)
  end

  def self.validate(*)
  end

  include Interval

  def update!(**attrs)
    attrs.each { |key, value| public_send("#{key}=", value) }
  end
end
