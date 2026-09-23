RSpec.describe GIAS::Reconciliation::Open do
  describe "#open!" do
    subject(:service) { described_class.new(gias_school).open! }

    let!(:gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:gias_school_can_be_opened?) { true }
    let(:gias_school_can_be_opened_after_split?) { false }
    let(:eligibility) do
      instance_double(
        GIAS::Reconciliation::Eligibility,
        can_be_opened?: gias_school_can_be_opened?,
        can_be_opened_after_split?: gias_school_can_be_opened_after_split?
      )
    end

    before do
      allow(GIAS::Reconciliation::Eligibility).to receive(:new).with(gias_school).and_return(eligibility)
    end

    it { is_expected.to be_truthy }

    it "creates a school" do
      expect { service }.to change(School, :count).by(1)
    end

    it "associates the school with the GIAS school" do
      service

      gias_school.reload
      expect(gias_school.school).to be_present
    end

    it "records a school opened event with the current date" do
      service

      school = gias_school.reload.school
      event = Event.where(event_type: "school_opened").sole
      expect(event.school_id).to eq(school.id)
      expect(event.metadata).to eq("gias_school_urn" => gias_school.urn, "gias_school_name" => gias_school.name)
      expect(event.happened_at.to_date).to eq(Date.current)
    end

    context "when the school can be split" do
      let(:gias_school_can_be_opened_after_split?) { true }
      let(:gias_school_can_be_opened?) { false }

      it { is_expected.to be_truthy }

      it "creates a school" do
        expect { service }.to change(School, :count).by(1)
      end

      it "associates the school with the GIAS school" do
        service

        gias_school.reload
        expect(gias_school.school).to be_present
      end
    end

    context "when GIAS provides an opening date" do
      let!(:gias_school) { FactoryBot.create(:gias_school, status: :open, opened_on: Date.yesterday) }

      it "records a school opened event with the provided date" do
        service

        school = gias_school.reload.school
        event = Event.where(event_type: "school_opened").sole
        expect(event.school_id).to eq(school.id)
        expect(event.happened_at.to_date).to eq(Date.yesterday)
      end
    end

    context "when the school cannot be opened" do
      let(:gias_school_can_be_opened?) { false }

      it { is_expected.to be_falsy }

      it "does not create a school" do
        expect { service }.not_to(change(School, :count))
      end

      it "does not associate a school with the GIAS school" do
        service

        gias_school.reload
        expect(gias_school.school).to be_nil
      end

      it "does not record an event" do
        service

        expect(Event.where(event_type: "school_opened")).to be_empty
      end
    end
  end
end
