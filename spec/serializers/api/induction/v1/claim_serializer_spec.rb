RSpec.describe API::Induction::V1::ClaimSerializer do
  it "serializes the claim" do
    claim = { trn: "1234567", full_name: "Kirk Van Houten", started_on: Date.new(2026, 1, 4), training_programme: "school_led" }

    expect(JSON.parse(described_class.render(claim))).to eq(
      "trn" => "1234567",
      "full_name" => "Kirk Van Houten",
      "started_on" => "2026-01-04",
      "training_programme" => "school_led"
    )
  end
end
