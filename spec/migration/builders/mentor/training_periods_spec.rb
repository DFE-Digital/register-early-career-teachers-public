describe Builders::Mentor::TrainingPeriods do
  include SchoolPartnershipHelpers

  subject(:service) { described_class.new(teacher:, training_period_data:) }

  let(:school_1) { FactoryBot.create(:school, urn: "123456") }
  let(:school_2) { FactoryBot.create(:school, urn: "987654") }
  let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
  let(:partnership_1) { make_partnership_for(school_1, contract_period) }
  let(:partnership_2) { make_partnership_for(school_2, contract_period, lead_provider_name: 'Naruto Ninja Academy ') }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:started_on) { contract_period.started_on }

  let!(:school_period_1) { FactoryBot.create(:mentor_at_school_period, started_on:, finished_on: started_on + 10.months, teacher:, school: school_1) }
  let!(:school_period_2) { FactoryBot.create(:mentor_at_school_period, started_on: started_on + 12.months, finished_on: nil, teacher:, school: school_2) }
  let(:training_period_1) { FactoryBot.build(:training_period_data, school_urn: school_1.urn, cohort_year: contract_period.year, lead_provider: partnership_1.lead_provider.name, delivery_partner: partnership_1.delivery_partner.name, start_date: school_period_1.started_on, end_date: school_period_1.finished_on) }
  let(:training_period_2) { FactoryBot.build(:training_period_data, school_urn: school_2.urn, cohort_year: contract_period.year, lead_provider: partnership_2.lead_provider.name, delivery_partner: partnership_2.delivery_partner.name, start_date: school_period_2.started_on, end_date: nil) }
  let(:training_period_data) { [training_period_1, training_period_2] }

  before do
    CacheManager.instance.clear_all_caches!
  end

  describe "#build" do
    it "creates TrainingPeriod records for the school periods" do
      expect {
        service.build
      }.to change { TrainingPeriod.count }.by(2)
    end

    it "populates the TrainingPeriod records with the correct information" do
      service.build
      periods = TrainingPeriod.where(mentor_at_school_period_id: teacher.mentor_at_school_periods.select(:id)).order(:started_on)

      expect(periods.first.school_partnership).to eq partnership_1
      expect(periods.first.started_on).to eq training_period_1.start_date
      expect(periods.first.finished_on).to eq training_period_1.end_date
      expect(periods.first.ecf_start_induction_record_id).to eq training_period_1.start_source_id
      expect(periods.first.ecf_end_induction_record_id).to eq training_period_1.end_source_id

      expect(periods.last.school_partnership).to eq partnership_2
      expect(periods.last.started_on).to eq training_period_2.start_date
      expect(periods.last.finished_on).to be_blank
      expect(periods.last.ecf_start_induction_record_id).to eq training_period_2.start_source_id
      expect(periods.last.ecf_end_induction_record_id).to eq training_period_2.end_source_id
    end

    context "when a mentor training period is school-led" do
      let(:training_period_2) { FactoryBot.build(:training_period_data, school_urn: school_2.urn, cohort_year: contract_period.year, lead_provider: partnership_2.lead_provider.name, delivery_partner: partnership_2.delivery_partner.name, training_programme: "school_led", start_date: school_period_2.started_on, end_date: nil) }

      it "does not create a TeacherMigrationFailure record" do
        expect {
          service.build
        }.not_to(change { TeacherMigrationFailure.count })
      end
    end

    context "when there is no MentorAtSchoolPeriod that contains the training dates" do
      let(:training_period_1) { FactoryBot.build(:training_period_data, cohort_year: contract_period.year, lead_provider: partnership_1.lead_provider.name, delivery_partner: partnership_1.delivery_partner.name, start_date: 14.months.ago.to_date, end_date: 1.month.ago.to_date) }

      it "creates a TeacherMigrationFailure record" do
        expect {
          service.build
        }.to change { TeacherMigrationFailure.count }.by(1)
      end
    end
  end
end
