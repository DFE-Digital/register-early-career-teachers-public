RSpec.describe Metadata::Manager do
  let(:instance) { described_class.new }
  let(:objects) { FactoryBot.build_list(:school, 2) }
  let(:handler) { instance_double(Metadata::Handler::School) }

  before { objects.each { allow(Metadata::Resolver).to receive(:resolve_handler).with(it).and_return(handler) } }

  describe "#create_metadata!" do
    subject(:create_metadata) { instance.create_metadata!(objects) }

    it "calls create_metadata! on the resolved handler" do
      objects.each { expect(handler).to receive(:create_metadata!).with(it) }
      create_metadata
    end
  end

  describe "#update_metadata!" do
    subject(:update_metadata) { instance.update_metadata!(objects) }

    it "calls update_metadata on the resolved handler" do
      objects.each { expect(handler).to receive(:update_metadata!).with(it) }
      update_metadata
    end
  end
end
