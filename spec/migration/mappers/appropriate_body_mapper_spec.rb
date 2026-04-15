describe Mappers::AppropriateBodyMapper do
  subject { Mappers::AppropriateBodyMapper.new }

  it "loads the hardcoded mapping data by default" do
    expect(subject.mapping_data).to be_an(Array)
    expect(subject.mapping_data.length).to eq(212)
  end

  describe "#get_ecf2_id" do
    it "returns the correct ECF2 ID given an ECF1 ID" do
      expect(subject.get_ecf2_id("d39267fc-ded1-49e0-b6ae-1161b3f3b439")).to eq(383)
    end
  end
end
