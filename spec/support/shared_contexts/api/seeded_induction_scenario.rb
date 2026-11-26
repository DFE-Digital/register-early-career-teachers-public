RSpec.shared_context "seeded induction API request scenarios" do
  include_context "with seeds", %w[
    contract_periods
    lead_providers
    regions
    schools
    appropriate_bodies
    delivery_partners
    lead_provider_delivery_partnerships
    school_partnerships
    schedules_and_milestones
    contracts
    statements
    api/induction
  ]

  include_context "test TRS API returns a teacher"

  let(:appropriate_body_name) { "Golden Leaf Teaching School Hub" }

  let(:appropriate_body_period) do
    AppropriateBodyPeriod.with_display_name(appropriate_body_name).first!
  end

  let(:authorization) do
    FactoryBot.create(:api_oauth_authorization, :with_token,
                      appropriate_body_period:)
  end

  def claim(trn, authorization: self.authorization, **params)
    headers = bearer_auth_headers(authorization:)
    post("/api/induction/v1/teachers/#{trn}/claim", params:, headers:, as: :json)
  end

  def pass(trn, authorization: self.authorization, **params)
    headers = bearer_auth_headers(authorization:)
    post("/api/induction/v1/teachers/#{trn}/pass", params:, headers:, as: :json)
  end

  def release(trn, authorization: self.authorization, **params)
    headers = bearer_auth_headers(authorization:)
    post("/api/induction/v1/teachers/#{trn}/release", params:, headers:, as: :json)
  end
end
