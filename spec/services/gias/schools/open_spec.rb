RSpec.describe GIAS::Schools::Open do
  describe ".call" do
    let!(:first_openable_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let!(:second_openable_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let!(:closed_gias_school) { FactoryBot.create(:gias_school, status: :closed) }
    let(:predecessor_gias_school) { FactoryBot.create(:gias_school) }
    let(:open_gias_school_with_predecessor) { FactoryBot.create(:gias_school, status: :open) }
    let!(:school_link) { FactoryBot.create(:gias_school_link, from_gias_school: predecessor_gias_school, to_gias_school: open_gias_school_with_predecessor) }
    let(:already_opened_gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

    it "only opens openable GIAS schools" do
      expect { described_class.call }.to change(School, :count).by(2)

      expect(first_openable_gias_school.reload.school).to be_present
      expect(second_openable_gias_school.reload.school).to be_present
    end

    xit "logs an event when opening a school" do
      expect { described_class.call }.to change(Event, :count).by(2)

      Event.last
      # TODO
    end
  end

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
      let!(:school_link) { FactoryBot.create(:gias_school_link, from_gias_school: predecessor_gias_school, to_gias_school: gias_school) }

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

      let!(:school_link) { FactoryBot.create(:gias_school_link, from_gias_school: gias_school, to_gias_school: successor_gias_school) }

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
