RSpec.describe GIAS::Schools::ECTAtSchoolPeriods::Transfer do
  let(:author) { Events::SystemAuthor.new }
  let(:predecessor_gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:predecessor_school) { predecessor_gias_school.school }
  let(:successor_school) { gias_school.school }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school: predecessor_school, started_on:, finished_on:) }

  let(:started_on) { Date.new(2025, 1, 1) }
  let(:finished_on) { Date.new(2025, 12, 31) }

  describe ".call" do
    subject { described_class.call(ect_at_school_period:, predecessor_school:, successor_school:) }

    it "updates the ect_at_school_period's school to the successor school" do
      subject
      expect(ect_at_school_period.school).to eq(successor_school)
    end

    it "records an event for the ect_at_school_period being moved to the successor school" do
      expect(Events::Record).to receive(:record_teacher_ect_at_school_period_moved_school!).with(
        teacher: ect_at_school_period.teacher,
        ect_at_school_period:,
        old_school_name: predecessor_gias_school.name,
        new_school: successor_school,
        happened_at: predecessor_gias_school.closed_on,
        author: an_instance_of(Events::SystemAuthor)
      )

      subject
    end

    context "when the ect_at_school_period has associated training periods" do
      context "when the training_period only has an expression of interest" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :with_only_expression_of_interest, ect_at_school_period:) }

        it "updates the ect_at_school_period's school to the successor school but makes no change to the training_period" do
          expect { subject }.not_to(change { training_period })

          expect(ect_at_school_period.school).to eq(successor_school)
        end
      end

      context "when the training period is linked to a school partnership" do
        let(:lead_provider_delivery_partnership) { training_period.school_partnership.lead_provider_delivery_partnership }
        let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :with_school_partnership, ect_at_school_period:) }

        it "updates the training_period to have a matching school partnership at the successor school" do
          subject

          expect(training_period.reload.school_partnership.school).to eq(successor_school)
          expect(training_period.school_partnership.lead_provider_delivery_partnership).to eq(lead_provider_delivery_partnership)
        end
      end
    end

    context "when the ect_at_school_period has associated events" do
      context "when the event is linked to the predecessor school" do
        let!(:event) { FactoryBot.create(:event, ect_at_school_period:, school: predecessor_school) }

        it "changes the event to point to the successor period" do
          expect { subject }.to change { event.reload.school }.to(successor_school)
        end
      end

      context "when the event is linked to a school partnership" do
        let(:training_period) { FactoryBot.create(:training_period, :for_ect, :with_school_partnership, ect_at_school_period:) }
        let!(:event) { FactoryBot.create(:event, ect_at_school_period:, school_partnership: training_period.school_partnership) }

        it "changes the event to point to the successor period" do
          expect { subject }.to change { event.reload.school_partnership.school }.to(successor_school)
        end
      end
    end
  end
end
