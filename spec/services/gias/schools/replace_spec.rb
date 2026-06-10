RSpec.describe GIAS::Schools::Replace do
  describe "#replace!" do
    subject(:service) { described_class.new(gias_school).replace! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed) }
    let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:other_gias_school) { FactoryBot.create(:gias_school) }
    let!(:school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor_gias_school) }
    let(:link_type) { :successor_unique }

    context "when the school is being replaced one-one" do
      it "replaces the URN with the new one" do
        service

        expect(gias_school.school.reload.urn).to eq(successor_gias_school.urn)
      end

      it "records a school changed event" do
        expect(Events::Record).to receive(:record_school_changed_event!).with(
          school: gias_school.school,
          new_gias_school: successor_gias_school,
          old_gias_school: gias_school,
          happened_at: successor_gias_school.opened_on,
          author: an_instance_of(Events::SystemAuthor)
        ).once

        service
      end
    end

    context "when the successor school is not yet open" do
      let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_open) }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school has not yet closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :proposed_to_close) }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school has already been created" do
      let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school is merging into a new school" do
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: other_gias_school, to_gias_school: successor_gias_school) }
      let(:link_type) { :successor_merged }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school is amalgamating into a new school" do
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: other_gias_school, to_gias_school: successor_gias_school) }
      let(:link_type) { :successor_amalgamated }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school is splitting into several schools" do
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: other_gias_school) }
      let(:link_type) { :successor_split }

      it_behaves_like "does not change the schools URN or record an event"
    end

    context "when the school has multiple successor schools" do
      let!(:other_school_link) { FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school, to_gias_school: other_gias_school) }

      it_behaves_like "does not change the schools URN or record an event"
    end
  end
end
