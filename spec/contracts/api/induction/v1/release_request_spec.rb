RSpec.describe API::Induction::V1::ReleaseRequest do
  it "parses the release" do
    params = ActionController::Parameters.new(teacher_trn: "1234567", release: { released_on: "2026-07-20", number_of_terms: 3 })

    expect(described_class.parse(params)).to eq(trn: "1234567", released_on: "2026-07-20", number_of_terms: 3)
  end
end
