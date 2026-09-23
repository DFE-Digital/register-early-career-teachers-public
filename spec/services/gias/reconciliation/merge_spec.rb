RSpec.describe GIAS::Reconciliation::Merge do
  subject(:service) { described_class.new(gias_school) }

  let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.yesterday) }
  let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, :open) }
  let(:predecessor_school) { gias_school.school }
  let(:successor_school) { successor_gias_school.school }

  let!(:school_link) do
    FactoryBot.create(
      :gias_school_link,
      :successor_merged,
      from_gias_school: gias_school,
      to_gias_school: successor_gias_school
    )
  end

  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school: predecessor_school) }
  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school: predecessor_school) }

  let(:eligibility) { instance_double(GIAS::Reconciliation::Eligibility) }

  describe "#merge!" do
    subject(:merge!) { service.merge! }

    before do
      allow(GIAS::Reconciliation::Eligibility).to receive(:new).with(gias_school).and_return(eligibility)
      allow(eligibility).to receive(:can_be_merged?).and_return(gias_school_can_be_merged?)
    end

    context "when the GIAS school cannot be merged" do
      let(:gias_school_can_be_merged?) { false }

      it { expect(merge!).to be_falsey }

      it "does not find any overlapping `MentorAtSchoolPeriod` records" do
        expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping).not_to receive(:find)

        merge!
      end

      it "does not merge any `MentorAtSchoolPeriod` records" do
        expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge).not_to receive(:call)

        merge!
      end

      it "does not transfer any `MentorAtSchoolPeriod` records" do
        expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer).not_to receive(:call)

        merge!
      end

      it "does not transfer any `ECTAtSchoolPeriod` records" do
        expect(GIAS::Reconciliation::ECTAtSchoolPeriods::Transfer).not_to receive(:call)

        merge!
      end

      it "does not record a school merged event" do
        merge!

        expect(Event.where(event_type: "school_merged")).to be_empty
      end

      it "does not destroy the predecessor school" do
        merge!

        expect(School).to exist(predecessor_school.id)
      end

      context "when there are events associated with the predecessor school" do
        let!(:event) { FactoryBot.create(:event, school: predecessor_school) }

        it "does not destroy any events associated with the predecessor school" do
          merge!

          expect(Event).to exist(event.id)
        end
      end

      context "when there are school_partnerships associated with the predecessor school" do
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }

        it "does not destroy any school_partnerships associated with the predecessor school" do
          merge!

          expect(SchoolPartnership).to exist(school_partnership.id)
        end
      end
    end

    context "when the GIAS school can be merged" do
      let(:gias_school_can_be_merged?) { true }

      before do
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping).to receive(:find).and_call_original
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge).to receive(:call).and_call_original
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer).to receive(:call).and_call_original
        allow(GIAS::Reconciliation::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original
      end

      it { expect(merge!).to be_truthy }

      context "when the successor school does not have a school record" do
        let(:successor_gias_school) { FactoryBot.create(:gias_school, :open) }

        it "creates a school record for the successor GIAS school" do
          merge!

          expect(successor_gias_school.reload.school).to be_present
        end

        it "records a school opened event for the successor GIAS school" do
          merge!

          event = Event.where(event_type: "school_opened").sole
          expect(event.school_id).to eq(successor_gias_school.reload.school.id)
          expect(event.metadata).to eq(
            "gias_school_urn" => successor_gias_school.urn,
            "gias_school_name" => successor_gias_school.name
          )
          expect(event.happened_at.to_date).to eq(gias_school.closed_on)
        end

        it "does not merge any records because there are none at the successor school" do
          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge).not_to receive(:call)

          merge!
        end

        it "transfers all `MentorAtSchoolPeriod` records" do
          merge!

          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer)
            .to have_received(:call)
            .with(
              mentor_at_school_period:,
              predecessor_school:,
              successor_school:
            )
        end
      end

      context "when the successor school already has a school record" do
        let(:mentor_at_two_schools_teacher) { FactoryBot.create(:teacher) }
        let!(:overlapping_mentor_at_school_period_1) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher: mentor_at_two_schools_teacher,
            school: predecessor_school,
            started_on: 1.year.ago
          )
        end
        let!(:overlapping_mentor_at_school_period_2) do
          FactoryBot.create(
            :mentor_at_school_period,
            teacher: mentor_at_two_schools_teacher,
            school: successor_school,
            started_on: 6.months.ago
          )
        end

        it "finds overlapping `MentorAtSchoolPeriod` records for each teacher mentoring at the school" do
          merge!

          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping)
            .to have_received(:find)
            .with(
              teacher: mentor_at_two_schools_teacher,
              schools: [predecessor_school, successor_school]
            )

          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping)
            .to have_received(:find)
            .with(
              teacher: mentor_at_school_period.teacher,
              schools: [predecessor_school, successor_school]
            )
        end

        it "merges overlapping `MentorAtSchoolPeriod` records" do
          merge!

          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge)
            .to have_received(:call)
            .with(
              periods: [overlapping_mentor_at_school_period_1, overlapping_mentor_at_school_period_2],
              predecessor_school:,
              successor_school:
            )
        end

        it "transfers remaining `MentorAtSchoolPeriod` records" do
          merge!

          expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer)
            .to have_received(:call)
            .with(
              mentor_at_school_period:,
              predecessor_school:,
              successor_school:
            )
        end
      end

      it "transfers remaining `ECTAtSchoolPeriod` records" do
        merge!

        expect(GIAS::Reconciliation::ECTAtSchoolPeriods::Transfer)
          .to have_received(:call)
          .with(
            ect_at_school_period:,
            predecessor_school:,
            successor_school:
          )
      end

      it "destroys the predecessor school" do
        merge!

        expect(School).not_to exist(predecessor_school.id)
      end

      context "when there are events associated with the predecessor school" do
        let!(:event) { FactoryBot.create(:event, school: predecessor_school) }

        it "deletes any events associated with the predecessor school" do
          merge!

          expect(Event).not_to exist(school_id: predecessor_school.id)
        end
      end

      context "when there are school_partnerships associated with the predecessor school" do
        let!(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }

        it "destroys any school_partnerships associated with the predecessor school" do
          merge!

          expect(SchoolPartnership).not_to exist(school_partnership.id)
        end
      end

      it "records a school merged event" do
        merge!

        event = Event.where(event_type: "school_merged").sole
        expect(event.school_id).to eq(successor_school.id)
        expect(event.metadata).to eq(
          "predecessor_gias_school_urn" => gias_school.urn,
          "predecessor_gias_school_name" => gias_school.name,
          "successor_gias_school_urn" => successor_gias_school.urn,
          "successor_gias_school_name" => successor_gias_school.name
        )
        expect(event.happened_at.to_date).to eq(gias_school.closed_on)
      end
    end
  end
end
