describe Builders::Mentor::SchoolPeriods do
  let(:school_1) { FactoryBot.create(:school, urn: "123456") }
  let(:school_2) { FactoryBot.create(:school, urn: "987654") }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:period_1) { FactoryBot.build(:school_period, urn: school_1.urn, start_date: 1.year.ago.to_date, end_date: 1.month.ago.to_date) }
  let(:period_2) { FactoryBot.build(:school_period, urn: school_2.urn, start_date: 1.month.ago.to_date, end_date: nil) }
  let(:school_periods) { [period_1, period_2] }

  subject(:service) { described_class.new(teacher:, school_periods:) }

  describe "#build" do
    it "creates MentorAtSchoolPeriod records for the school periods" do
      expect {
        service.build
      }.to change { teacher.mentor_at_school_periods.count }.by(2)
    end

    it "populates the MentorAtSchoolPeriod records with the correct information" do
      service.build
      periods = teacher.mentor_at_school_periods.order(:started_on)

      expect(periods.first.school).to eq school_1
      expect(periods.first.started_on).to eq period_1.start_date
      expect(periods.first.finished_on).to eq period_1.end_date
      expect(periods.first.ecf_start_induction_record_id).to eq period_1.start_source_id
      expect(periods.first.ecf_end_induction_record_id).to eq period_1.end_source_id

      expect(periods.last.school).to eq school_2
      expect(periods.last.started_on).to eq period_2.start_date
      expect(periods.last.finished_on).to be_blank
      expect(periods.last.ecf_start_induction_record_id).to eq period_2.start_source_id
      expect(periods.last.ecf_end_induction_record_id).to eq period_2.end_source_id
    end

    context "when the school does not exist" do
      let(:period_1) { FactoryBot.build(:school_period, urn: "12121", start_date: 1.year.ago.to_date, end_date: 1.month.ago.to_date) }

      it "creates a TeacherMigrationFailure record" do
        expect {
          service.build
        }.to change { TeacherMigrationFailure.count }.by(1)
      end
    end

    context "when the school period dates overlap" do
      let(:period_2) { FactoryBot.build(:school_period, urn: school_2.urn, start_date: 2.months.ago.to_date, end_date: nil) }

      it "does not create a TeacherMigrationFailure record" do
        expect {
          service.build
        }.not_to(change { TeacherMigrationFailure.count })
      end
    end
  end
end
