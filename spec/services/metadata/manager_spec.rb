RSpec.describe Metadata::Manager do
  let(:instance) { described_class.new }
  let(:objects) { FactoryBot.build_list(:school, 2) }
  let(:handler) { instance_double(Metadata::Handlers::School) }

  describe "#refresh_metadata!" do
    subject(:refresh_metadata) { instance.refresh_metadata!(objects) }

    it "calls refresh_metadata! on the resolved handler for all objects" do
      objects.each do
        handler = instance_double(Metadata::Handlers::School)

        allow(Metadata::Handlers::School).to receive(:new).with(it) { handler }
        expect(handler).to receive(:refresh_metadata!).once
      end

      refresh_metadata
    end

    context "when given a single object" do
      let(:objects) { FactoryBot.build(:school) }

      it "calls refresh_metadata! on the resolved handler for the single object" do
        handler = instance_double(Metadata::Handlers::School)

        allow(Metadata::Handlers::School).to receive(:new).with(objects) { handler }
        expect(handler).to receive(:refresh_metadata!).once

        refresh_metadata
      end
    end
  end
end
