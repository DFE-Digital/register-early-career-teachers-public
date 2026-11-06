RSpec.describe API::Induction::V1::ClaimRequest do
  it "parses the claim" do
    params = ActionController::Parameters.new(
      teacher_trn: "1234567",
      claim: { date_of_birth: "2001-05-13", claimed_from: "2026-01-04", training_programme: "school_led" }
    )

    expect(described_class.parse(params)).to eq(
      trn: "1234567",
      date_of_birth: "2001-05-13",
      claimed_from: "2026-01-04",
      training_programme: "school_led"
    )
  end
end
