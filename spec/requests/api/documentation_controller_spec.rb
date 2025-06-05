RSpec.describe API::DocumentationController, type: :request do
  subject { response }

  before { get api_documentation_path(version:) }

  context "with v3" do
    let(:version) { "v3" }

    it { is_expected.to have_http_status :success }
  end

  context "with v4" do
    let(:version) { "v4" }

    it { is_expected.to have_http_status :not_found }
  end

  context "without version" do
    let(:version) { "" }

    it { is_expected.to have_http_status :not_found }
  end
end
