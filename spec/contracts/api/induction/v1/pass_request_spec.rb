RSpec.describe API::Induction::V1::PassRequest do
  it "parses the pass" do
    params = ActionController::Parameters.new(teacher_trn: "1234567", pass: { passed_on: "2026-07-20", number_of_terms: 3 })

    expect(described_class.parse(params)).to eq(trn: "1234567", passed_on: "2026-07-20", number_of_terms: 3)
  end
end
