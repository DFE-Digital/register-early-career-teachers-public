describe Builders::MentorshipPeriods do
  subject(:service) { described_class.new(teacher:, mentorship_period_data:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:started_on) { 2.years.ago.to_date }
  let(:finished_on) { 6.months.ago.to_date }
  let!(:ect_period) { FactoryBot.create(:ect_at_school_period, :active, teacher:, started_on:, finished_on:) }
  let(:mentor_period_1) do
    FactoryBot.create(:mentor_at_school_period,
                      :active,
                      school: ect_period.school,
                      started_on: started_on + 1.day)
  end
  let(:mentor_period_2) do
    FactoryBot.create(:mentor_at_school_period,
                      :active,
                      school: ect_period.school,
                      started_on: started_on - 1.week)
  end

  let(:mentorship_period_1) do
    FactoryBot.build(:mentorship_period_data,
                     mentor_teacher: mentor_period_1.teacher,
                     start_date: started_on + 2.days,
                     end_date: started_on + 2.weeks)
  end
  let(:mentorship_period_2) do
    FactoryBot.build(:mentorship_period_data,
                     mentor_teacher: mentor_period_2.teacher,
                     start_date: started_on + 1.month,
                     end_date: started_on + 3.months)
  end
  let(:mentorship_period_data) { [mentorship_period_1, mentorship_period_2] }

  describe "#build" do
    it "creates MentorshipPeriod records for the mentorship periods" do
      expect {
        service.build
      }.to change { MentorshipPeriod.count }.by(2)
    end

    it "populates the MentorshipPeriod records with the correct information" do
      service.build
      periods = ect_period.mentorship_periods.order(:started_on)

      expect(periods.first.mentor).to eq mentor_period_1
      expect(periods.first.started_on).to eq mentorship_period_1.start_date
      expect(periods.first.finished_on).to eq mentorship_period_1.end_date
      expect(periods.first.ecf_start_induction_record_id).to eq mentorship_period_1.start_source_id
      expect(periods.first.ecf_end_induction_record_id).to eq mentorship_period_1.end_source_id

      expect(periods.last.mentor).to eq mentor_period_2
      expect(periods.last.started_on).to eq mentorship_period_2.start_date
      expect(periods.last.finished_on).to eq mentorship_period_2.end_date
      expect(periods.last.ecf_start_induction_record_id).to eq mentorship_period_2.start_source_id
      expect(periods.last.ecf_end_induction_record_id).to eq mentorship_period_2.end_source_id
    end

    context "when there is no ECTAtSchoolPeriod that contains the training dates" do
      let!(:ect_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: started_on + 1.month, finished_on:) }

      it "creates a TeacherMigrationFailure record" do
        expect {
          service.build
        }.to change { TeacherMigrationFailure.count }.by(1)
      end

      it "stores an error message in the failure record" do
        service.build
        expect(teacher.teacher_migration_failures.first.message).to eq "No ECTAtSchoolPeriod found for mentorship dates"
      end
    end

    context "when there is no MentorAtSchoolPeriod that contains the training dates" do
      let(:mentor_period_2) { FactoryBot.create(:mentor_at_school_period, school: ect_period.school, started_on: 1.month.ago) }

      it "creates a TeacherMigrationFailure record" do
        expect {
          service.build
        }.to change { TeacherMigrationFailure.count }.by(1)
      end

      it "stores an error message in the failure record" do
        service.build
        expect(teacher.teacher_migration_failures.first.message).to eq "No MentorAtSchoolPeriod found for mentorship dates"
      end
    end

    context "when the mentor does not have a MentorAtSchoolPeriod at the same school" do
      let(:mentor_period_1) { FactoryBot.create(:mentor_at_school_period, :active, started_on: started_on + 1.day) }

      it "creates a TeacherMigrationFailure record" do
        expect {
          service.build
        }.to change { TeacherMigrationFailure.count }.by(1)
      end

      it "stores an error message in the failure record" do
        service.build
        expect(teacher.teacher_migration_failures.first.message).to eq "No MentorAtSchoolPeriod found for mentorship dates"
      end
    end
  end
end
