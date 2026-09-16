RSpec.describe GIAS::Reconciliation::Replace do
  describe "#replace!" do
    subject(:service) { described_class.new(gias_school).replace! }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:) }
    let(:closed_on) { Date.yesterday }
    let(:successor_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:other_gias_school) { FactoryBot.create(:gias_school) }
    let!(:school_link) { FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor_gias_school) }
    let(:link_type) { :successor_unique }
    let(:eligibility) { instance_double(GIAS::Reconciliation::Eligibility) }

    before do
      allow(GIAS::Reconciliation::Eligibility).to receive(:new).with(gias_school).and_return(eligibility)
      allow(eligibility).to receive(:can_be_replaced?).and_return(gias_school_can_be_replaced?)
    end

    context "when the school can be replaced" do
      let(:gias_school_can_be_replaced?) { true }

      it { is_expected.to be_truthy }

      it "replaces the URN with the new one" do
        service

        expect(gias_school.school.reload.urn).to eq(successor_gias_school.urn)
      end

      it "records a school changed event" do
        school = gias_school.school

        subject

        event = Event.where(event_type: "school_changed").sole
        expect(event.school_id).to eq(school.id)
        expect(event.metadata).to eq(
          "old_gias_school_urn" => gias_school.urn,
          "old_gias_school_name" => gias_school.name,
          "new_gias_school_urn" => successor_gias_school.urn,
          "new_gias_school_name" => successor_gias_school.name
        )
        expect(event.happened_at.to_date).to eq(closed_on)
      end

      context "when there are ECTs at the school" do
        let!(:old_school_name) { Schools::Name.new(gias_school.school).name_and_urn }

        before do
          FactoryBot.create_list(:ect_at_school_period, 2, school: gias_school.school)
        end

        it "records an event for each ECT moved" do
          moved_periods = gias_school.school.ect_at_school_periods.to_a

          subject

          events = Event.where(event_type: "teacher_ect_at_school_period_moved_school")
          expect(events.map(&:ect_at_school_period_id)).to match_array(moved_periods.map(&:id))
          expect(events.map(&:school_id).uniq).to eq([successor_gias_school.school.id])
          expect(events.map { |e| e.metadata["old_school_name_and_urn"] }.uniq).to eq([old_school_name])
        end
      end

      context "when there are Mentors at the school" do
        let!(:old_school_name) { Schools::Name.new(gias_school.school).name_and_urn }

        before do
          FactoryBot.create_list(:mentor_at_school_period, 2, school: gias_school.school)
        end

        it "records an event for each Mentor moved" do
          moved_periods = gias_school.school.mentor_at_school_periods.to_a

          subject

          events = Event.where(event_type: "teacher_mentor_at_school_period_moved_school")
          expect(events.map(&:mentor_at_school_period_id)).to match_array(moved_periods.map(&:id))
          expect(events.map(&:school_id).uniq).to eq([successor_gias_school.school.id])
          expect(events.map { |e| e.metadata["old_school_name_and_urn"] }.uniq).to eq([old_school_name])
        end
      end
    end

    context "when the school is cannot be replaced" do
      let(:gias_school_can_be_replaced?) { false }

      it { is_expected.to be_falsy }

      it "does not update the school's URN" do
        expect { subject }.not_to(change { gias_school.school.reload.urn })
      end

      it "does not record a school changed event" do
        subject

        expect(Event.where(event_type: "school_changed")).to be_empty
      end

      context "when there are ECTs at the school" do
        before do
          FactoryBot.create_list(:ect_at_school_period, 2, school: gias_school.school)
        end

        it "does not record an event for each ECT moved" do
          subject

          expect(Event.where(event_type: "teacher_ect_at_school_period_moved_school")).to be_empty
        end
      end

      context "when there are Mentors at the school" do
        before do
          FactoryBot.create_list(:mentor_at_school_period, 2, school: gias_school.school)
        end

        it "does not record an event for each Mentor moved" do
          subject

          expect(Event.where(event_type: "teacher_mentor_at_school_period_moved_school")).to be_empty
        end
      end
    end
  end
end
