RSpec.describe API::Induction::V1::ReleaseSerializer do
  it "serializes the release" do
    release = { trn: "1234567", full_name: "Kirk Van Houten", released_on: Date.new(2026, 7, 20), number_of_terms: 3.0 }

    expect(JSON.parse(described_class.render(release))).to eq(
      "trn" => "1234567",
      "full_name" => "Kirk Van Houten",
      "released_on" => "2026-07-20",
      "number_of_terms" => 3.0
    )
  end
end
