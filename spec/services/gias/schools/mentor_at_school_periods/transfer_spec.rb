RSpec.describe GIAS::Schools::MentorAtSchoolPeriods::Transfer do
  let(:author) { Events::SystemAuthor.new }
  let(:predecessor_gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:predecessor_school) { predecessor_gias_school.school }
  let(:successor_school) { gias_school.school }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school: predecessor_school, started_on:, finished_on:) }

  let(:started_on) { Date.new(2025, 1, 1) }
  let(:finished_on) { Date.new(2025, 12, 31) }

  describe ".call" do
    subject { described_class.call(period: mentor_at_school_period, predecessor_school:, successor_school:) }

    it "updates the mentor_at_school_period's school to the successor school" do
      subject
      expect(mentor_at_school_period.school).to eq(successor_school)
    end

    context "when the mentor_at_school_period has associated training periods" do
      context "when the training period has only an expression of interest" do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :with_only_expression_of_interest, mentor_at_school_period:) }

        it "updates the mentor_at_school_period's school to the successor school but makes no change to the training_period" do
          expect { subject }.not_to(change { training_period })

          expect(mentor_at_school_period.school).to eq(successor_school)
        end
      end

      context "when the training period is linked to a school partnership" do
        let(:lead_provider_delivery_partnership) { training_period.school_partnership.lead_provider_delivery_partnership }
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :with_school_partnership, mentor_at_school_period:) }

        it "updates the training_period to have a matching school partnership at the successor school" do
          subject

          expect(training_period.school_partnership.school).to eq(successor_school)
          expect(training_period.school_partnership.lead_provider_delivery_partnership).to eq(lead_provider_delivery_partnership)
        end
      end
    end

    context "when the mentor_at_school_period has associated events" do
      context "when the event is linked to the predecessor school" do
        let!(:event) { FactoryBot.create(:event, mentor_at_school_period:, school: predecessor_school) }

        it "changes the event to point to the successor period" do
          expect { subject }.to change { event.reload.school }.to(successor_school)
        end
      end

      context "when the event is linked to a school partnership" do
        let(:training_period) { FactoryBot.create(:training_period, :for_mentor, :with_school_partnership, mentor_at_school_period:) }
        let!(:event) { FactoryBot.create(:event, mentor_at_school_period:, school_partnership: training_period.school_partnership) }

        it "changes the event to point to the successor period" do
          expect { subject }.to change { event.reload.school_partnership.school }.to(successor_school)
        end
      end
    end

    context "when the mentor_at_school_period has associated mentorship periods" do
      let(:ect_at_school_periods) { FactoryBot.create_list(:ect_at_school_period, 2, school: predecessor_school, started_on:, finished_on:) }
      let(:mentor) { mentor_at_school_period }

      before do
        ect_at_school_periods.each do |mentee|
          FactoryBot.create(:mentorship_period, mentor:, mentee:, started_on:, finished_on:)
        end
      end

      it "calls GIAS::Schools::ECTAtSchoolPeriods::Transfer for each mentorship_period's mentee" do
        ect_at_school_periods.each do |_mentee|
          allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original
        end

        subject

        ect_at_school_periods.each do |mentee|
          expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to have_received(:call).with(period: mentee, predecessor_school:, successor_school:)
        end
      end
    end
  end
end
