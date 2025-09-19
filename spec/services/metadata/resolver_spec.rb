RSpec.describe Metadata::Resolver do
  describe ".resolve_handler" do
    it "returns the correct handler for a known object type" do
      object = School.new
      handler = Metadata::Resolver.resolve_handler(object)
      expect(handler).to be_a(Metadata::Handlers::School)
      expect(handler.school).to eq(object)
    end

    it "raises an error for an unknown object type" do
      unknown_object = Class.new
      expect {
        Metadata::Resolver.resolve_handler(unknown_object)
      }.to raise_error(ArgumentError, "No metadata handler found for Class")
    end
  end

  describe ".all_handlers" do
    subject { described_class.all_handlers }

    it { is_expected.to contain_exactly(Metadata::Handlers::School, Metadata::Handlers::DeliveryPartner, Metadata::Handlers::Teacher) }
  end
end
