RSpec.describe MentorAtSchoolPeriods::LatestRegistrationChoices do
  subject(:service) { described_class.new(trn: teacher.trn) }

  let(:teacher) { FactoryBot.create(:teacher) }

  context "when the latest training period has a confirmed partnership" do
    let(:school_partnership) { FactoryBot.create(:school_partnership) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        school_partnership:,
        started_on: mentor_at_school_period.started_on,
        mentor_at_school_period:
      )
    end

    describe "#training_period" do
      it "returns the latest training period for the mentor TRN" do
        expect(service.training_period).to eq(training_period)
      end
    end

    describe "#confirmed_training_period" do
      it "returns the latest confirmed training period for the mentor TRN" do
        expect(service.confirmed_training_period).to eq(training_period)
      end
    end

    describe "#school" do
      it "returns the school from the partnership" do
        expect(service.school).to eq(school_partnership.school)
      end
    end

    describe "#lead_provider" do
      it "returns the lead provider from the partnership" do
        expect(service.lead_provider).to eq(school_partnership.lead_provider)
      end
    end

    describe "#delivery_partner" do
      it "returns the delivery partner from the partnership" do
        expect(service.delivery_partner).to eq(school_partnership.delivery_partner)
      end
    end
  end

  context "when the latest training period has an EOI (no partnership)" do
    let(:school) { FactoryBot.create(:school) }
    let(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
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

    describe "#training_period" do
      it "returns the latest training period (the EOI-only one)" do
        expect(service.training_period).to eq(training_period)
      end
    end

    describe "#confirmed_training_period" do
      it "returns nil because there is no confirmed period" do
        expect(service.confirmed_training_period).to be_nil
      end
    end

    describe "#school" do
      it "returns the school from the mentor_at_school_period when only an EOI exists" do
        expect(service.school).to eq(school)
      end
    end

    describe "#lead_provider" do
      it "returns the lead provider from the expression of interest (EOI)" do
        expect(service.lead_provider).to eq(lp_from_eoi)
      end
    end

    describe "#delivery_partner" do
      it "returns nil" do
        expect(service.delivery_partner).to be_nil
      end
    end
  end

  context "when there are no training periods for the TRN" do
    describe "#training_period" do
      it "returns nil" do
        expect(service.training_period).to be_nil
      end
    end

    describe "#confirmed_training_period" do
      it "returns nil" do
        expect(service.confirmed_training_period).to be_nil
      end
    end

    describe "#school" do
      it "returns nil" do
        expect(service.school).to be_nil
      end
    end

    describe "#lead_provider" do
      it "returns nil" do
        expect(service.lead_provider).to be_nil
      end
    end

    describe "#delivery_partner" do
      it "returns nil" do
        expect(service.delivery_partner).to be_nil
      end
    end
  end
end
