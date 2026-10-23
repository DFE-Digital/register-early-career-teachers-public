RSpec.describe DfESignIn::AccessRequestJob do
  subject(:job) { described_class.new }

  describe "#perform" do
    subject(:perform) { job.perform(organisation_id:, user_id:, role_ids:) }

    let(:api_client) { instance_double(DfESignIn::APIClient) }

    let(:organisation_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }
    let(:role_ids) { %w[SchoolUser] }

    before do
      allow(DfESignIn::APIClient).to receive(:new).and_return(api_client)
    end

    it "makes an access request to DfE Sign-in" do
      expect(api_client)
        .to receive(:access_requests)
        .with(organisation_id:, user_id:, role_ids:)
        .once

      perform
    end
  end
end
