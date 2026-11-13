describe "api/documentation/show.html.erb" do
  subject { rendered }

  before { render }

  it { is_expected.to have_css("h1", text: "Register early career teachers APIs") }

  it { is_expected.to have_css("h2", text: "Authorisation") }
  it { is_expected.to have_link("Read the authorisation guidance", href: api_documentation_authorisation_path) }

  it { is_expected.to have_css("h2", text: "Hello API") }
  it { is_expected.to have_link("View the Hello API", href: api_hello_documentation_path) }

  context "when the training API feature flag is set to true", with_feature_flags: { enable_training_api: true } do
    it { is_expected.to have_css("h2", text: "Training API") }
    it { is_expected.to have_link("View the Training API", href: api_training_v4_documentation_path) }
  end

  context "when the training API feature flag is set to false", with_feature_flags: { enable_training_api: false } do
    it { is_expected.not_to have_css("h2", text: "Training API") }
    it { is_expected.not_to have_link("View the Training API", href: api_training_v4_documentation_path) }
  end

  it { is_expected.to have_css("h2", text: "Induction API") }
  it { is_expected.to have_link("View the Induction API", href: api_induction_v1_documentation_path) }
end
