RSpec.describe Statements::API::Query do
  shared_examples "preloaded associations" do
    it { expect(result.association(:active_lead_provider)).to be_loaded }
  end

  describe "preloading relationships" do
    let(:instance) { described_class.new }

    let!(:statement) { FactoryBot.create(:statement) }

    describe "#statements" do
      subject(:result) { instance.statements.first }

      include_context "preloaded associations"
    end

    describe "#statement_by_api_id" do
      subject(:result) { instance.statement_by_api_id(statement.api_id) }

      include_context "preloaded associations"
    end

    describe "#statement_by_id" do
      subject(:result) { instance.statement_by_id(statement.id) }

      include_context "preloaded associations"
    end
  end
end
