class FakeRangeQueryClass
  include Queries::RangeQueries

  def self.table_name = "a_fake_table"
end

describe Queries::RangeQueries do
  let(:start) { Date.new(2001, 1, 1) }
  let(:finish) { Date.new(2001, 2, 2) }

  describe ".date_in_range_inclusive_start_exclusive_end" do
    subject { FakeRangeQueryClass.date_in_range_inclusive_start_exclusive_end(start) }

    let(:clause) { %{"a_fake_table"."range" @> date(?)} }

    it { is_expected.to eql([clause, start]) }
  end

  describe ".date_in_range_inclusive_start_inclusive_end" do
    subject { FakeRangeQueryClass.date_in_range_inclusive_start_inclusive_end(start) }

    let(:clause) do
      %(
        daterange(
          lower("a_fake_table"."range"),
          upper("a_fake_table"."range"),
          '[]'
        ) @> date(?)
      )
    end

    it { is_expected.to eql([clause.squish, start]) }
  end

  describe ".containing_range" do
    subject { FakeRangeQueryClass.containing_range(start, finish) }

    let(:clause) { %{"a_fake_table"."range" @> daterange(?, ?)} }

    it { is_expected.to eql([clause, start, finish]) }
  end

  describe ".overlapping_with_range" do
    subject { FakeRangeQueryClass.overlapping_with_range(start, finish) }

    let(:clause) { %{"a_fake_table"."range" && daterange(?, ?)} }

    it { is_expected.to eql([clause, start, finish]) }
  end
end
