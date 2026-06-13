RSpec.describe GIAS::Schools::Open do
  describe "#open!" do
    subject(:service) { described_class.new(gias_school).open! }

    let!(:gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:openable) { true }

    before do
      allow(gias_school).to receive(:openable?).and_return(openable)
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

    it "records a school opened event" do
      allow(Events::Record).to receive(:record_school_opened_event!)

      service

      school = gias_school.reload.school

      expect(Events::Record).to have_received(:record_school_opened_event!).with(
        school:,
        gias_school:,
        happened_at: gias_school.opened_on,
        author: an_instance_of(Events::SystemAuthor)
      ).once
    end

    context "when the school is not openable" do
      let(:openable) { false }

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
        expect { service }.not_to(change(Event, :count))
      end
    end
  end
end
