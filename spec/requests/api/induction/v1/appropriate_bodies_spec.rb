RSpec.describe "GET /api/induction/v1/appropriate-bodies", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client) }

  describe "ordering by name" do
    let!(:golden_leaf) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub: FactoryBot.create(:teaching_school_hub, name: "Golden Leaf Teaching School Hub"),
                        name: "Golden Leaf Teaching School Hub")
    end

    let!(:bright_futures) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                        teaching_school_hub: FactoryBot.create(:teaching_school_hub, name: "Bright Futures Teaching School Hub"),
                        name: "Bright Futures Teaching School Hub")
    end

    before do
      FactoryBot.create(:appropriate_body_period, :cannot_sign_in, name: "Oldshire Local Authority")
    end

    context "with and without appropriate body period names" do
      before do
        bright_futures.update!(name: nil)
      end

      it "returns the active appropriate bodies ordered by name" do
        get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([
          { "id" => bright_futures.external_id, "name" => "Bright Futures Teaching School Hub" },
          { "id" => golden_leaf.external_id, "name" => "Golden Leaf Teaching School Hub" },
        ])
      end
    end

    context "with appropriate body period names" do
      let!(:bright_futures_2) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub: bright_futures.teaching_school_hub,
                          name: "Bright Futures Teaching School Hub 2nd Provisioner")
      end

      it "returns the active appropriate bodies ordered by name" do
        get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([
          { "id" => bright_futures.external_id, "name" => "Bright Futures Teaching School Hub" },
          { "id" => bright_futures_2.external_id, "name" => "Bright Futures Teaching School Hub 2nd Provisioner" },
          { "id" => golden_leaf.external_id, "name" => "Golden Leaf Teaching School Hub" },
        ])
      end
    end
  end

  it "names each period with no name of its own after its body type record, with no query per row" do
    %i[teaching_school_hub national local_authority teaching_school].each do |body_type|
      abp = FactoryBot.create(:appropriate_body_period, body_type)
      # Factory initializes by name
      abp.update_columns(name: nil, dfe_sign_in_organisation_id: SecureRandom.uuid)
    end

    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:)

    display_names = AppropriateBodyPeriod.active.map(&:display_name)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("name")).to match_array(display_names)
    expect(response.parsed_body.pluck("name")).to all(be_present)
  end

  it "rejects bad client credentials" do
    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:, secret: "wrong")
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("error" => "invalid_client")

    unknown_client = FactoryBot.build(:api_oauth_client)
    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client: unknown_client)
    expect(response).to have_http_status(:unauthorized)

    get "/api/induction/v1/appropriate-bodies"
    expect(response).to have_http_status(:unauthorized)
  end
end
