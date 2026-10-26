RSpec.describe API::Induction::V1::InductionPeriodSerializer, type: :serializer do
  let(:teacher) { FactoryBot.create(:teacher, :with_name, trn: "1234567") }
  let(:induction_period) do
    FactoryBot.create(:induction_period, :pass, teacher:, started_on: "2024-09-01", finished_on: "2025-07-20", number_of_terms: 3)
  end

  it "serializes the induction period" do
    expect(JSON.parse(described_class.render(induction_period), symbolize_names: true)).to eq(
      trn: "1234567",
      full_name: "John Keating",
      status: "pass",
      started_on: "2024-09-01",
      finished_on: "2025-07-20",
      training_programme: "provider_led",
      number_of_terms: 3.0
    )
  end
end
