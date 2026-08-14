RSpec.describe GIAS::Reconciliation::Merge do
  subject(:service) { described_class.new(gias_school) }

  let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :closed) }
  let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, :open) }
  let!(:school_link) do
    FactoryBot.create(
      :gias_school_link,
      :successor_merged,
      from_gias_school: gias_school,
      to_gias_school: successor_gias_school
    )
  end
  let(:eligibility) { instance_double(GIAS::Reconciliation::Eligibility) }

  describe "#merge!" do
    subject(:merge!) { service.merge! }

    let(:predecessor_school) { gias_school.school }
    let(:successor_school) { successor_gias_school.school }

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
    end

    context "when the GIAS school can be merged" do
      let(:gias_school_can_be_merged?) { true }

      let(:predecessor_school) { FactoryBot.create(:school) }
      let(:gias_school) do
        FactoryBot.create(
          :gias_school,
          :with_school,
          :closed,
          school: predecessor_school
        )
      end

      let(:mentor_teacher) { FactoryBot.create(:teacher) }
      let!(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher: mentor_teacher,
          school: predecessor_school
        )
      end
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          school: predecessor_school
        )
      end

      before do
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping)
          .to receive(:find)
          .and_return([[mentor_at_school_period]])
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge).to receive(:call)
        allow(GIAS::Reconciliation::MentorAtSchoolPeriods::Transfer).to receive(:call)
        allow(GIAS::Reconciliation::ECTAtSchoolPeriods::Transfer).to receive(:call)
        allow(Events::Record).to receive(:record_school_merged_event!)
      end

      it { expect(merge!).to be_truthy }

      it "finds overlapping `MentorAtSchoolPeriod` records for each mentor teacher" do
        merge!

        expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Overlapping)
          .to have_received(:find)
          .with(
            teacher: mentor_teacher,
            schools: [predecessor_school, successor_school]
          )
      end

      it "merges overlapping `MentorAtSchoolPeriod` records" do
        merge!

        expect(GIAS::Reconciliation::MentorAtSchoolPeriods::Merge)
          .to have_received(:call)
          .with(
            periods: [mentor_at_school_period],
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

      it "records a school merged event" do
        merge!

        expect(Events::Record)
          .to have_received(:record_school_merged_event!)
          .with(
            school: predecessor_school,
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
