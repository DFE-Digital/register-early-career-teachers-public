describe GIASHelpers do
  describe "scopes" do
    let!(:open_school) { FactoryBot.create(:school, :open) }
    let!(:eligible_school) { FactoryBot.create(:school, :eligible) }
    let!(:cip_only_school) { FactoryBot.create(:school, :cip_only) }
    let!(:not_cip_only_school) { FactoryBot.create(:school, :not_cip_only) }

    describe ".in_gias_schools" do
      it "returns schools with linked `gias_schools` records" do
        expect(School.in_gias_schools).to contain_exactly(open_school,
                                                          eligible_school,
                                                          cip_only_school,
                                                          not_cip_only_school)
      end
    end

    describe '.eligible' do
      it "returns eligible schools only" do
        expect(School.eligible).to contain_exactly(open_school,
                                                   eligible_school,
                                                   not_cip_only_school)
      end
    end

    describe '.cip_only' do
      it "returns `cip`/`school-led` schools only" do
        expect(School.cip_only).to contain_exactly(cip_only_school)
      end
    end

    describe '.not_cip_only' do
      it "returns not `cip`/`school-led` schools only" do
        expect(School.not_cip_only).to contain_exactly(open_school,
                                                       eligible_school,
                                                       not_cip_only_school)
      end
    end
  end

  describe "#independent?" do
    subject(:school) { FactoryBot.create(:school, :independent) }

    it { is_expected.to be_independent }

    context 'when the school is not independent' do
      subject(:school) { FactoryBot.create(:school, :eligible) }

      it { is_expected.not_to be_independent }
    end
  end

  describe "#state_funded?" do
    subject(:school) { FactoryBot.create(:school, :state_funded) }

    it { is_expected.to be_state_funded }

    context 'when the school is not state funded' do
      subject(:school) { FactoryBot.create(:school, :independent) }

      it { is_expected.not_to be_state_funded }
    end
  end
end
