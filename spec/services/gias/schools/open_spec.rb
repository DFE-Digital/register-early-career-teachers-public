RSpec.describe GIAS::Schools::Open do
  describe "#open!" do
    subject(:service) { described_class.new(gias_school).open! }

    context "for open GIAS schools without a school record" do
      let!(:gias_school) { FactoryBot.create(:gias_school, status: :open) }

      it "creates a school" do
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
    end

    context "for closed GIAS schools" do
      let!(:gias_school) { FactoryBot.create(:gias_school, status: :closed) }

      it "does not create a school" do
        expect { service }.not_to(change(gias_school, :school))
      end

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "for open GIAS schools with predecessors" do
      let(:predecessor_gias_school) { FactoryBot.create(:gias_school) }
      let(:gias_school) { FactoryBot.create(:gias_school, status: :open) }
      let!(:school_link) { FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: gias_school, to_gias_school: predecessor_gias_school) }

      it "does not create a school" do
        expect { service }.not_to(change(gias_school, :school))
      end

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "for open GIAS schools with successors" do
      let(:successor_gias_school) { FactoryBot.create(:gias_school) }
      let(:gias_school) { FactoryBot.create(:gias_school, status: :open) }

      let!(:school_link) { FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school, to_gias_school: successor_gias_school) }

      it "does not create a school" do
        expect { service }.not_to(change(gias_school, :school))
      end

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end

    context "for open GIAS schools that have already been opened" do
      let!(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      it "does not create a school" do
        expect { service }.not_to(change(gias_school, :school))
      end

      it "does not record an event" do
        expect { service }.not_to(change(Event, :count))
      end
    end
  end
end
