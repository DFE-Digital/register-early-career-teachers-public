RSpec.describe GIAS::Reconciliation::Merge do
  subject(:service) { described_class.new(gias_school) }

  let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :closed) }
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
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school: predecessor_school) }
  let!(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      school: predecessor_school
    )
  end

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
        expect(Events::Record).not_to receive(:record_school_merged_event!)

        merge!
      end

      it "does not destroy any events associated with the predecessor school" do
        FactoryBot.create(:event, school: predecessor_school)

        expect { merge! }.not_to(change { predecessor_school.events.count })
      end

      it "does not destroy any school_partnerships associated with the predecessor school" do
        FactoryBot.create(:school_partnership, school: predecessor_school)

        expect { merge! }.not_to(change { predecessor_school.school_partnerships.count })
      end

      it "does not destroy the predecessor school" do
        expect { merge! }.not_to change { School.exists?(predecessor_school.id) }.from(true)
      end
    end

    context "when the GIAS school can be merged" do
      let(:gias_school_can_be_merged?) { true }

      before do
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping).to receive(:find).and_call_original
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge).to receive(:call).and_call_original
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer).to receive(:call).and_call_original
        allow(GIAS::Reconciliation::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original
        allow(Events::Record).to receive(:record_school_merged_event!)
      end

      it { expect(merge!).to be_truthy }

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

      it "deletes any events associated with the predecessor school" do
        event = FactoryBot.create(:event, school: predecessor_school)

        expect { merge! }.to change { Event.exists?(event.id) }.from(true).to(false)
      end

      it "destroys any school_partnerships associated with the predecessor school" do
        school_partnership = FactoryBot.create(:school_partnership, school: predecessor_school)

        expect { merge! }.to change { SchoolPartnership.exists?(school_partnership.id) }.from(true).to(false)
      end

      it "destroys the school" do
        expect { merge! }.to change { School.exists?(predecessor_school.id) }.from(true).to(false)
      end

      it "records a school merged event" do
        merge!

        expect(Events::Record)
          .to have_received(:record_school_merged_event!)
          .with(
            school: successor_school,
            successor_gias_school:,
            predecessor_gias_school: gias_school,
            happened_at: gias_school.closed_on,
            author: an_instance_of(Events::SystemAuthor)
          )
      end

      context "when the successor school does not have a school record" do
        let(:successor_gias_school) { FactoryBot.create(:gias_school, :open) }

        it "creates a school record for the successor GIAS school" do
          expect { merge! }.to change(School, :count).by(1)

          expect(successor_gias_school.reload.school).to be_present
        end

        it "records a school opened event for the successor GIAS school" do
          allow(Events::Record).to receive(:record_school_opened_event!)

          merge!

          expect(Events::Record)
            .to have_received(:record_school_opened_event!)
            .with(
              school: successor_gias_school.reload.school,
              gias_school: successor_gias_school,
              happened_at: gias_school.closed_on,
              author: an_instance_of(Events::SystemAuthor)
            )
        end
      end
    end
  end
end
