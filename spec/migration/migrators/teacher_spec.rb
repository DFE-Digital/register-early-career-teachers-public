RSpec.describe Migrators::Teacher do
  it_behaves_like "a migrator", :teacher, [:school_partnership] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)
      school = ect.school_cohort.school
      cohort = ect.school_cohort.cohort
      partnership = FactoryBot.create(:migration_partnership, school:, cohort:)
      induction_programme = ect.school_cohort.default_induction_programme
      FactoryBot.create(:migration_provider_relationship, lead_provider: partnership.lead_provider, delivery_partner: partnership.delivery_partner, cohort: partnership.cohort)
      induction_programme.update!(partnership:)
      ect.teacher_profile
    end

    def create_resource(migration_resource)
      ect = migration_resource.participant_profiles.first
      school_cohort = ect.school_cohort
      partnership = school_cohort.school.partnerships.first

      school = FactoryBot.create(:school, urn: school_cohort.school.urn)

      lead_provider = FactoryBot.create(:lead_provider, name: partnership.lead_provider.name, ecf_id: partnership.lead_provider_id)
      delivery_partner = FactoryBot.create(:delivery_partner, name: partnership.delivery_partner.name, api_id: partnership.delivery_partner_id)
      contract_period = FactoryBot.create(:contract_period, year: school_cohort.cohort.start_year)
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp)
    end

    def setup_failure_state
      invalid_trn = '123'
      teacher_profile = FactoryBot.create(:migration_teacher_profile, trn: invalid_trn)
      ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)
    end

    describe "#migrate!" do
      it 'creates Teacher records for each ECF TeacherProfile with TRN' do
        teacher_profile = FactoryBot.create(:migration_teacher_profile)
        ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user)
        FactoryBot.create(:migration_induction_record, participant_profile: ect)

        instance.migrate!

        user = teacher_profile.user
        teacher = ::Teacher.find_by!(trn: teacher_profile.trn)
        parser = Teachers::FullNameParser.new(full_name: user.full_name)

        expect(teacher.trnless).to be false
        expect(Teachers::Name.new(teacher).full_name).to eq [parser.first_name, parser.last_name].join(" ")
        expect(teacher.created_at).to be_within(1.second).of teacher_profile.created_at
        expect(teacher.updated_at).to be_within(1.second).of teacher_profile.updated_at
      end

      it 'creates trnless Teacher records for ECF TeacherProfiles without TRN' do
        teacher_profile_without_trn = FactoryBot.create(:migration_teacher_profile, trn: nil)
        ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_without_trn, user: teacher_profile_without_trn.user)
        FactoryBot.create(:migration_induction_record, participant_profile: ect)

        instance.migrate!

        user = teacher_profile_without_trn.user
        teacher = ::Teacher.find_by!(api_id: user.id)
        parser = Teachers::FullNameParser.new(full_name: user.full_name)

        expect(teacher.trnless).to be true
        expect(teacher.trn).to be_nil
        expect(Teachers::Name.new(teacher).full_name).to eq [parser.first_name, parser.last_name].join(" ")
        expect(teacher.created_at).to be_within(1.second).of teacher_profile_without_trn.created_at
        expect(teacher.updated_at).to be_within(1.second).of teacher_profile_without_trn.updated_at
      end

      context 'for teachers with TRN' do
        it 'creates an ECTAtSchoolPeriod records for each school period found in the ECF induction records' do
          instance.migrate!

          Migration::TeacherProfile.where.not(trn: nil).find_each do |teacher_profile|
            teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

            teacher_profile.participant_profiles.first.induction_records.each do |induction_record|
              expect(teacher.ect_pupil_premium_uplift).to eq(teacher_profile.participant_profiles.first.pupil_premium_uplift)
              expect(teacher.ect_sparsity_uplift).to eq(teacher_profile.participant_profiles.first.sparsity_uplift)
              expect(teacher.ect_at_school_periods.first.started_on.to_date).to eq induction_record.start_date.to_date
              expect(teacher.ect_at_school_periods.first.school.urn).to eq induction_record.induction_programme.school_cohort.school.urn.to_i
            end
          end
        end

        it 'creates a TrainingPeriod record for each partnership period found in the ECF induction records' do
          instance.migrate!

          Migration::TeacherProfile.where.not(trn: nil).find_each do |teacher_profile|
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

      context 'for trnless teachers' do
        let!(:trnless_teacher_profile) { FactoryBot.create(:migration_teacher_profile, trn: nil) }
        let!(:trnless_ect) { FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: trnless_teacher_profile, user: trnless_teacher_profile.user) }
        let!(:trnless_induction_record) do
          FactoryBot.create(:migration_induction_record, participant_profile: trnless_ect).tap do |induction_record|
            school = induction_record.induction_programme.school_cohort.school
            cohort = induction_record.induction_programme.school_cohort.cohort
            partnership = FactoryBot.create(:migration_partnership, school:, cohort:)
            induction_programme = induction_record.induction_programme
            FactoryBot.create(:migration_provider_relationship, lead_provider: partnership.lead_provider, delivery_partner: partnership.delivery_partner, cohort: partnership.cohort)
            induction_programme.update!(partnership:)
          end
        end

        it 'creates an ECTAtSchoolPeriod record for school period found in the ECF induction records' do
          # Create RECT dependencies
          create_resource(trnless_teacher_profile)

          instance.migrate!

          teacher = ::Teacher.find_by!(api_id: trnless_teacher_profile.user.id)

          expect(teacher.ect_pupil_premium_uplift).to eq(trnless_ect.pupil_premium_uplift)
          expect(teacher.ect_sparsity_uplift).to eq(trnless_ect.sparsity_uplift)
          expect(teacher.ect_at_school_periods.first.started_on.to_date).to eq trnless_induction_record.start_date.to_date
          expect(teacher.ect_at_school_periods.first.school.urn).to eq trnless_induction_record.induction_programme.school_cohort.school.urn.to_i
        end

        it 'creates a TrainingPeriod record for partnership period found in the ECF induction records' do
          # Create RECT dependencies
          create_resource(trnless_teacher_profile)

          instance.migrate!

          teacher = ::Teacher.find_by!(api_id: trnless_teacher_profile.user.id)
          training_period = ::TrainingPeriod.find_by!(ecf_start_induction_record_id: trnless_induction_record.id)

          expect(training_period.ect_at_school_period.teacher).to eq teacher
          expect(training_period.started_on.to_date).to eq trnless_induction_record.start_date.to_date
          expect(training_period.school_partnership.school.urn).to eq trnless_induction_record.induction_programme.school_cohort.school.urn.to_i
          expect(training_period.school_partnership.lead_provider.name).to eq trnless_induction_record.induction_programme.partnership.lead_provider.name
        end
      end
    end

    describe ".teachers" do
      it "includes teacher profiles with and without TRN" do
        teacher_profile_with_nil_trn = FactoryBot.create(:migration_teacher_profile, trn: nil)
        ect_without_trn = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_nil_trn, user: teacher_profile_with_nil_trn.user)
        FactoryBot.create(:migration_induction_record, participant_profile: ect_without_trn)

        teacher_profile_with_valid_trn = FactoryBot.create(:migration_teacher_profile)
        ect_with_trn = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_valid_trn, user: teacher_profile_with_valid_trn.user)
        FactoryBot.create(:migration_induction_record, participant_profile: ect_with_trn)

        teachers = described_class.teachers
        expect(teachers).to include(teacher_profile_with_valid_trn)
        expect(teachers).to include(teacher_profile_with_nil_trn)
      end
    end
  end
end
