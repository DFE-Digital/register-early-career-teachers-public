RSpec.describe GIAS::Schools::Replace do
  describe "#replace!" do
    subject(:service) { described_class.new(gias_school).replace! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed) }
    let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let!(:school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor_gias_school ) }
    let(:link_type) { :successor_unique }

    context "when the school is being replaced one-one" do
      it "updates the school's URN to match the successor GIAS school's URN" do
        service

        expect(gias_school.school.reload.urn).to eq(successor_gias_school.urn)
      end

      it "records a school changed event" do
        allow(Events::Record).to receive(:record_school_changed_event!)

        service

        expect(Events::Record).to have_received(:record_school_changed_event!).with(
          school: gias_school.school,
          new_gias_school: successor_gias_school,
          old_gias_school: gias_school,
          happened_at: successor_gias_school.opened_on,
          author: an_instance_of(Events::SystemAuthor)
        ).once
      end
    end

    context "when the successor school is not yet open" do
      let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_open) }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end

    context "when the school is merging into a new school" do
      let(:other_gias_school) { FactoryBot.create(:gias_school) }
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: other_gias_school, to_gias_school: successor_gias_school) }
      let(:link_type) { :successor_merged }

      it "does not update the school's URN" do
        service

        expect(gias_school.school.reload.urn).not_to eq(successor_gias_school.urn)
      end

      it "does not record a school changed event" do
        allow(Events::Record).to receive(:record_school_changed_event!)

        service

        expect(Events::Record).not_to have_received(:record_school_changed_event!)
      end
    end

    context "when the school has already been created" do
      let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end

    context "when the school is splitting into two schools" do
      let(:other_successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: other_successor_gias_school) }
      let(:link_type) { :successor_split }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end

    context "when the school is amalgamating into a new school" do
      let(:other_gias_school) { FactoryBot.create(:gias_school) }
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: other_gias_school, to_gias_school: successor_gias_school) }
      let(:link_type) { :successor_amalgamated }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end

    context "when the school has multiple successor schools" do
      let(:other_successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school, to_gias_school: other_successor_gias_school) }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end


    context "when the school has not yet closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :proposed_to_close) }

      it "does not update the school's URN" do
        expect { service }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        expect { service }.not_to change(Event, :count)
      end
    end
  end
end
