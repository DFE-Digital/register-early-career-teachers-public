RSpec.shared_examples "a period which allows zero-length periods to overlap" do
  let(:overlap_date) { 2.months.ago.to_date }

  def build_zero_length_overlap_period(started_on:, finished_on:)
    FactoryBot.build(
      period_type,
      *traits,
      **attrs,
      started_on:,
      finished_on:
    )
  end

  def create_zero_length_overlap_period(started_on:, finished_on:)
    FactoryBot.create(
      period_type,
      *traits,
      **attrs,
      started_on:,
      finished_on:
    )
  end

  it "allows a zero-length period on a non-zero period's end date" do
    create_zero_length_overlap_period(started_on: overlap_date - 10.days, finished_on: overlap_date)
    period = build_zero_length_overlap_period(started_on: overlap_date, finished_on: overlap_date)

    expect(period).to be_valid
  end

  it "does not treat a zero-length sibling as overlapping a non-zero period" do
    create_zero_length_overlap_period(started_on: overlap_date, finished_on: overlap_date)
    period = build_zero_length_overlap_period(started_on: overlap_date - 10.days, finished_on: overlap_date + 10.days)

    expect(period).to be_valid
  end

  it "allows duplicate zero-length periods with the same sibling identity and start date" do
    first_period = create_zero_length_overlap_period(started_on: overlap_date, finished_on: overlap_date)
    second_period = create_zero_length_overlap_period(started_on: overlap_date, finished_on: overlap_date)

    expect(second_period).to be_persisted
    expect(second_period.id).not_to eq(first_period.id)
  end

  it "still rejects non-zero periods that share an endpoint" do
    create_zero_length_overlap_period(started_on: overlap_date - 10.days, finished_on: overlap_date)
    period = build_zero_length_overlap_period(started_on: overlap_date, finished_on: overlap_date + 10.days)

    expect(period).not_to be_valid
  end
end
