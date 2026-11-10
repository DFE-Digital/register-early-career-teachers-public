RSpec.describe SelfDocumentable::Request do
  subject(:request_class) { API::Induction::V1::ClaimRequest }

  let(:params) do
    ActionController::Parameters.new(
      teacher_trn: "1234567",
      claim: { date_of_birth: "2001-05-13", claimed_from: "2026-01-04", training_programme: "school_led", full_name: "Kirk Van Houten" }
    )
  end

  it "builds an OpenAPI schema named after the request" do
    expect(request_class.openapi_schema_name).to eq("ClaimRequest")
    expect(request_class.openapi_ref).to eq("$ref": "#/components/schemas/ClaimRequest")
    expect(request_class.openapi_schema).to include(
      description: "Claim an early career teacher's induction",
      required: %i[date_of_birth claimed_from training_programme]
    )
  end

  it "keys the request body after the request" do
    expect(request_class.param_key).to eq(:claim)
  end

  it "drops fields it does not document" do
    expect(request_class.parse(params)).not_to have_key(:full_name)
  end

  it "rejects a missing body" do
    expect { request_class.parse(params.except(:claim)) }.to raise_error(ActionController::ParameterMissing)
  end

  it "maps the path parameter onto the parsed request" do
    expect(request_class.path_params).to eq(trn: :teacher_trn)
    expect(request_class.parse(params)).to include(trn: "1234567")
  end
end
