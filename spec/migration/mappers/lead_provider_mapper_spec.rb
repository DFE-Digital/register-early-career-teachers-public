describe Mappers::LeadProviderMapper do
  let(:mapper) { Mappers::LeadProviderMapper.new(index_by:) }

  describe "#get" do
    context "indexing by cpd_lead_provider_id" do
      let(:index_by) { :cpd_lead_provider_id }

      it "returns the id for a given cpd_lead_provider_id" do
        expect(mapper.get("9ad41410-677f-4da3-86a1-cda62b42e176").id).to eql("7a6753ef-6bb1-4fb3-ba93-fcbf3b20541b")
      end
    end

    context "indexing by name" do
      let(:index_by) { :name }

      it "returns the id for a given name" do
        expect(mapper.get("Education Development Trust").cpd_lead_provider_id).to eql("af89cf02-bbe0-423b-b2f6-bb2dbb97d141")
      end
    end

    context "indexing by id" do
      let(:index_by) { :id }

      it "returns the name for a given id" do
        expect(mapper.get("99317668-2942-4292-a895-fdb075af067b").name).to eql("Teach First")
      end
    end
  end
end
