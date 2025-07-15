describe GIASHelpers do
  describe "scopes" do
    let!(:open_school) { FactoryBot.create(:school, :open) }
    let!(:independent_school) { FactoryBot.create(:school, :independent) }
    let!(:state_funded_school) { FactoryBot.create(:school, :state_funded) }
    let!(:not_in_england_school) { FactoryBot.create(:school, :not_in_england) }
    let!(:not_open_school) { FactoryBot.create(:school, :not_open) }
    let!(:section_41_approved_school) { FactoryBot.create(:school, :section_41_approved) }
    let!(:eligible_school) { FactoryBot.create(:school, :eligible) }
    let!(:cip_only_school) { FactoryBot.create(:school, :cip_only) }
    let!(:not_cip_only_school) { FactoryBot.create(:school, :not_cip_only) }

    describe ".in_gias_schools" do
      it "returns schools with linked `gias_schools` records" do
        expect(School.in_gias_schools).to contain_exactly(open_school,
                                                          independent_school,
                                                          state_funded_school,
                                                          not_in_england_school,
                                                          not_open_school,
                                                          section_41_approved_school,
                                                          eligible_school,
                                                          cip_only_school,
                                                          not_cip_only_school)
      end
    end

    describe '.currently_open' do
      it "returns currently open schools only" do
        expect(School.currently_open).to contain_exactly(open_school,
                                                         independent_school,
                                                         state_funded_school,
                                                         not_in_england_school,
                                                         section_41_approved_school,
                                                         eligible_school,
                                                         cip_only_school,
                                                         not_cip_only_school)
      end
    end

    describe ".in_england" do
      it "returns schools in England only" do
        expect(School.in_england).to contain_exactly(open_school,
                                                     independent_school,
                                                     state_funded_school,
                                                     not_open_school,
                                                     section_41_approved_school,
                                                     eligible_school,
                                                     cip_only_school,
                                                     not_cip_only_school)
      end
    end

    describe '.section_41' do
      it "returns section 41 approved schools only" do
        expect(School.section_41).to contain_exactly(section_41_approved_school)
      end
    end

    describe '.eligible' do
      it "returns eligible schools only" do
        expect(School.eligible).to contain_exactly(open_school,
                                                   state_funded_school,
                                                   section_41_approved_school,
                                                   eligible_school,
                                                   not_cip_only_school)
      end
    end

    describe '.cip_only' do
      it "returns `cip`/`school-led` schools only" do
        expect(School.cip_only).to contain_exactly(independent_school,
                                                   cip_only_school)
      end
    end

    describe '.not_cip_only' do
      it "returns not `cip`/`school-led` schools only" do
        expect(School.not_cip_only).to contain_exactly(open_school,
                                                       state_funded_school,
                                                       not_in_england_school,
                                                       not_open_school,
                                                       section_41_approved_school,
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
