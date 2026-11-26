RSpec.describe APIRoute do
  subject { described_class.only(:training, :induction, :hello, :oauth, except: purposefully_unauthenticated + web_pages) }

  let(:purposefully_unauthenticated) { [API::Hello::WorldsController] }
  let(:web_pages) { [API::OAuth::AuthorizationsController] }

  it { is_expected.not_to be_empty }
  it { is_expected.to all(be_authenticated) }
end
