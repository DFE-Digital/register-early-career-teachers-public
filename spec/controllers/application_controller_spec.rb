RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      head :ok
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  let(:email) { "user@example.com" }
  let(:dfe_sign_in_user_id) { SecureRandom.uuid }
  let(:current_user) do
    FactoryBot.build(
      :school_user,
      :at_random_school,
      email:,
      dfe_sign_in_user_id:
    )
  end
  let(:dfe_sign_in_user_fingerprint) do
    OpenSSL::HMAC.hexdigest(
      "SHA256",
      Rails.application.secret_key_base,
      dfe_sign_in_user_id
    )
  end

  it "sets Sentry user context with a DfE Sign in user fingerprint" do
    allow(Sentry).to receive(:set_user)

    get :index

    expect(Sentry).to have_received(:set_user).with(
      email:,
      id: nil,
      dfe_sign_in_user_fingerprint:
    )
  end

  it "adds a fingerprinted DfE Sign in user ID to the log payload" do
    payload = {}

    controller.send(:append_info_to_payload, payload)

    expect(payload).to include(
      current_user_class: "Sessions::Users::SchoolUser",
      current_user_id: nil,
      current_user_dfe_sign_in_user_fingerprint: dfe_sign_in_user_fingerprint
    )
    expect(payload).not_to have_key(:current_user_dfe_sign_in_user_id)
  end
end
