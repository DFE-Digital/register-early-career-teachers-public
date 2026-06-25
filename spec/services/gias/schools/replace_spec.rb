RSpec.describe GIAS::Schools::Replace do
  describe "#replace!" do
    subject(:service) { described_class.new(gias_school).replace! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed) }
    let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:other_gias_school) { FactoryBot.create(:gias_school) }
    let!(:school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor_gias_school) }
    let(:link_type) { :successor_unique }

    before do
      allow(gias_school).to receive(:can_be_replaced?).and_return(can_be_replaced)
    end

    context "when the school can be replaced" do
      let(:can_be_replaced) { true }

      it { is_expected.to be_truthy }

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

        subject
      end
    end

    context "when the school is cannot be replaced" do
      let(:can_be_replaced) { false }

      it { is_expected.to be_falsy }

      it "does not update the school's URN" do
        expect { subject }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        allow(Events::Record).to receive(:record_school_changed_event!)

        subject

        expect(Events::Record).not_to have_received(:record_school_changed_event!)
      end
    end
  end
end
