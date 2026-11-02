RSpec.describe API::Induction::V1::ErrorSerializer do
  it "serializes the errors" do
    errors = [{ title: "Conflict", detail: "The teacher has an ongoing induction period with another appropriate body" }]

    expect(JSON.parse(described_class.render({ errors: }))).to eq(
      "errors" => [{ "title" => "Conflict", "detail" => "The teacher has an ongoing induction period with another appropriate body" }]
    )
  end
end
