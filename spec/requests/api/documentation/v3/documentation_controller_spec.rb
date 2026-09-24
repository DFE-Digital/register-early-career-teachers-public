RSpec.describe "Lead provider API docs", type: :request do
  subject { response }

  before { get api_docs_training_documentation_path }

  it { is_expected.to have_http_status :success }
end
