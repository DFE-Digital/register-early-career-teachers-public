describe "API Token tasks" do
  describe "api_token:lead_provider:generate_token" do
    subject :run_task do
      Rake::Task["api_token:lead_provider:generate_token"].invoke(lead_provider_name_or_id)
    end

    let(:lead_provider_name_or_id) {}
    let(:service) { instance_double(API::AddAPITokenToLeadProvider) }

    before do
      allow(API::AddAPITokenToLeadProvider).to receive(:new).and_return(service)
    end

    after do
      Rake::Task["api_token:lead_provider:generate_token"].reenable
    end

    it "calls the correct service class" do
      expect(API::AddAPITokenToLeadProvider).to receive(:new).with(
        lead_provider_name_or_id:,
        logger: Rails.logger
      )
      expect(service).to receive(:add)

      run_task
    end
  end
end
