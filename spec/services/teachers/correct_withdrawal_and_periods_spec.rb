RSpec.describe Teachers::CorrectWithdrawalAndPeriods do
  subject(:correct_withdrawal_and_periods) do
    described_class.new(
      ect_at_school_period:,
      author:
    ).correct!
  end

  let(:author) { Events::SystemAuthor.new }
  let(:started_on) { Date.new(2023, 9, 11) }
  let(:finished_on) { Date.new(2023, 11, 10) }
  let(:withdrawn_at) { Time.zone.parse("2025-11-06T12:20:55Z") }

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      started_on:,
      finished_on: nil
    )
  end

  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      school: ect_at_school_period.school,
      started_on:,
      finished_on: nil
    )
  end

  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      mentee: ect_at_school_period,
      mentor: mentor_at_school_period,
      started_on:,
      finished_on: nil
    )
  end

  let!(:original_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on:,
      finished_on: Date.new(2023, 11, 23),
      withdrawn_at: nil,
      withdrawal_reason: nil
    )
  end

  let!(:erroneous_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on: Date.new(2025, 10, 7),
      finished_on: Date.new(2025, 11, 6),
      withdrawn_at:,
      withdrawal_reason: "other"
    )
  end

  it "moves the withdrawal details onto the original training period" do
    correct_withdrawal_and_periods

    expect(original_training_period.reload).to have_attributes(
      withdrawn_at:,
      withdrawal_reason: "other"
    )
  end

  it "changes the original training period end date" do
    correct_withdrawal_and_periods

    expect(original_training_period.reload.finished_on).to eq(finished_on)
  end

  it "removes the erroneous training period" do
    expect { correct_withdrawal_and_periods }
      .to change { TrainingPeriod.exists?(erroneous_training_period.id) }
      .from(true)
      .to(false)
  end

  it "finishes the ECT-at-school period" do
    correct_withdrawal_and_periods

    expect(ect_at_school_period.reload.finished_on).to eq(finished_on)
  end

  it "finishes the mentorship period" do
    correct_withdrawal_and_periods

    expect(mentorship_period.reload.finished_on).to eq(finished_on)
  end

  it "does not record events" do
    expect { correct_withdrawal_and_periods }.not_to change(Event, :count)
  end
end
