RSpec.describe SchoolPartnerships::API::Query do
  shared_examples "preloaded associations" do
    it { expect(result.association(:delivery_partner)).to be_loaded }
    it { expect(result.association(:active_lead_provider)).to be_loaded }
    it { expect(result.association(:school)).to be_loaded }
    it { expect(result.school.association(:gias_school)).to be_loaded }
  end

  describe "preloading relationships" do
    let(:instance) { described_class.new }

    let!(:school_partnership) { FactoryBot.create(:school_partnership) }

    describe "#school_partnerships" do
      subject(:result) { instance.school_partnerships.first }

      include_context "preloaded associations"
    end

    describe "#school_partnership_by_api_id" do
      subject(:result) { instance.school_partnership_by_api_id(school_partnership.api_id) }

      include_context "preloaded associations"
    end

    describe "#school_partnership_by_id" do
      subject(:result) { instance.school_partnership_by_id(school_partnership.id) }

      include_context "preloaded associations"
    end
  end
end
