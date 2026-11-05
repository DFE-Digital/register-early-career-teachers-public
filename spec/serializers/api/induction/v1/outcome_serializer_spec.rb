RSpec.describe API::Induction::V1::OutcomeSerializer do
  it "serializes the outcome" do
    outcome = { trn: "1234567", full_name: "Kirk Van Houten", completed_on: Date.new(2026, 7, 20), number_of_terms: 3.0, outcome: "pass" }

    expect(JSON.parse(described_class.render(outcome))).to eq(
      "trn" => "1234567",
      "full_name" => "Kirk Van Houten",
      "completed_on" => "2026-07-20",
      "number_of_terms" => 3.0,
      "outcome" => "pass"
    )
  end
end
