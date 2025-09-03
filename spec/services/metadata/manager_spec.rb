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

    [nil, [], [nil]].each do |empty_value|
      context "when given #{empty_value}" do
        let(:objects) { empty_value }

        it "does not call resolve any handlers" do
          expect(Metadata::Resolver).not_to receive(:resolve_handler)
        end
      end
    end
  end

  describe ".refresh_all_metadata!" do
    subject(:refresh_all_metadata) { described_class.refresh_all_metadata!(async:) }

    let(:async) { true }

    it "calls refresh_metadata! for each handler with async: true" do
      expect(Metadata::Resolver.all_handlers).to all(receive(:refresh_all_metadata!).with(async:))

      refresh_all_metadata
    end

    context "when async is false" do
      let(:async) { false }

      it "calls refresh_metadata! for each handler with async: false" do
        expect(Metadata::Resolver.all_handlers).to all(receive(:refresh_all_metadata!).with(async:))

        refresh_all_metadata
      end
    end
  end

  describe ".destroy_all_metadata!" do
    subject(:destroy_all_metadata) { described_class.destroy_all_metadata! }

    it "calls destroy_all_metadata! for each handler" do
      expect(Metadata::Resolver.all_handlers).to all(receive(:destroy_all_metadata!))

      destroy_all_metadata
    end
  end
end
