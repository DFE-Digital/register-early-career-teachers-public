describe MentorAtSchoolPeriods::LatestRegistrationChoices do
  subject { MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: teacher.trn) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school: mentor_at_school_period.school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, school_partnership:, started_on: mentor_at_school_period.started_on, mentor_at_school_period:) }

  describe "#school" do
    it { expect(subject.school).to eq(school_partnership.school) }
  end

  describe "#lead_provider" do
    it { expect(subject.lead_provider).to eq(school_partnership.lead_provider) }
  end

  describe "#delivery_partner" do
    it { expect(subject.delivery_partner).to eq(school_partnership.delivery_partner) }
  end

  context "when the latest training period has an EOI (no partnership)" do
    let(:school) { FactoryBot.create(:school) }
    let!(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        school:
      )
    end

    let(:lp_from_eoi) { FactoryBot.create(:lead_provider, name: "EOI LP") }
    let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, lead_provider: lp_from_eoi) }

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        :with_no_school_partnership,
        mentor_at_school_period:,
        expression_of_interest:,
        training_programme: "provider_led"
      )
    end

    describe "#school" do
      it "returns the school from the mentor_at_school_period when only an EOI exists" do
        expect(subject.school).to eq(school)
      end
    end

    describe "#lead_provider" do
      it "returns the lead provider from the expression of interest (EOI)" do
        expect(subject.lead_provider).to eq(lp_from_eoi)
      end
    end

    describe "#delivery_partner" do
      it "returns nil" do
        expect(subject.delivery_partner).to be_nil
      end
    end
  end
end
