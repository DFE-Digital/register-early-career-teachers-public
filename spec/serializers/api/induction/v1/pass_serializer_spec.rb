RSpec.describe API::Induction::V1::PassSerializer do
  it "serializes the pass" do
    pass = { trn: "1234567", full_name: "Kirk Van Houten", passed_on: Date.new(2026, 7, 20), number_of_terms: 3.0 }

    expect(JSON.parse(described_class.render(pass))).to eq(
      "trn" => "1234567",
      "full_name" => "Kirk Van Houten",
      "passed_on" => "2026-07-20",
      "number_of_terms" => 3.0
    )
  end
end
