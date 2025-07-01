RSpec.describe Migrators::TrainingPeriod do
  it_behaves_like "a migrator", :training_period, %i[ect_at_school_period mentor_at_school_period school_partnership] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)
      school = ect.school_cohort.school
      cohort = ect.school_cohort.cohort
      induction_programme = ect.school_cohort.default_induction_programme

      induction_programme.update!(partnership: FactoryBot.create(:migration_partnership, school:, cohort:))
      ect.teacher_profile
    end

    def create_resource(migration_resource)
      teacher = FactoryBot.create(:teacher, trn: migration_resource.trn)
      ect = migration_resource.participant_profiles.first
      school_cohort = ect.school_cohort
      partnership = school_cohort.school.partnerships.first

      school = FactoryBot.create(:school, urn: school_cohort.school.urn)
      FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: school_cohort.default_induction_programme.induction_records.first.start_date, finished_on: nil)

      lead_provider = FactoryBot.create(:lead_provider, name: partnership.lead_provider.name, ecf_id: partnership.lead_provider_id)
      delivery_partner = FactoryBot.create(:delivery_partner, name: partnership.delivery_partner.name, api_id: partnership.delivery_partner_id)
      contract_period = FactoryBot.create(:contract_period, year: school_cohort.cohort.start_year)
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp)
    end

    def setup_failure_state
      # add but with no dependencies added
      create_migration_resource
    end

    describe "#migrate!" do
      it 'creates a TrainingPeriod record for each partnership period found in the ECF induction records' do
        instance.migrate!

        Migration::TeacherProfile.find_each do |teacher_profile|
          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

          teacher_profile.participant_profiles.first.induction_records.each do |induction_record|
            training_period = ::TrainingPeriod.find_by!(ecf_start_induction_record_id: induction_record.id)
            expect(training_period.ect_at_school_period.teacher).to eq teacher
            expect(training_period.started_on.to_date).to eq induction_record.start_date.to_date
            expect(training_period.school_partnership.school.urn).to eq induction_record.induction_programme.school_cohort.school.urn.to_i
            expect(training_period.school_partnership.lead_provider.name).to eq induction_record.induction_programme.partnership.lead_provider.name
          end
        end
      end
    end
  end
end
