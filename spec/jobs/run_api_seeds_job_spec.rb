RSpec.describe RunAPISeedsJob, type: :job do
  describe "#perform" do
    let(:api_seed_task) { instance_double(Rake::Task, invoke: nil) }
    let(:environment) { "review" }

    before do
      allow(Rails.application).to receive(:load_tasks)
      allow(Rails).to receive(:env) { environment.inquiry }
      allow(Rake::Task).to receive(:[]).with("api_seed_data:generate").and_return(api_seed_task)
    end

    it "loads Rails tasks" do
      described_class.new.perform

      expect(Rails.application).to have_received(:load_tasks)
    end

    it "invokes the `api_seed_data:generate` rake task" do
      described_class.new.perform

      expect(api_seed_task).to have_received(:invoke)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not invoke the `api_seed_data:generate` rake task" do
        described_class.new.perform

        expect(api_seed_task).not_to have_received(:invoke)
      end
    end
  end

  describe "queue" do
    it "is queued on the api_seeds queue" do
      expect(described_class.new.queue_name).to eq("api_seeds")
    end
  end
end
