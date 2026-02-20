describe ECF1TeacherHistory do
  describe "#initialize" do
    subject(:history) { described_class.new(user:, ect:, mentor:) }

    let(:user) { FactoryBot.build(:ecf1_teacher_history_user) }
    let(:ect_induction_records) do
      [
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 12.months.ago, end_date: 6.months.ago),
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 6.months.ago),
      ]
    end

    let(:mentor_at_school_periods) do
      [
        FactoryBot.build(:ecf1_teacher_history_mentor_at_school_period_row, started_on: 12.months.ago, finished_on: 6.months.ago),
        FactoryBot.build(:ecf1_teacher_history_mentor_at_school_period_row, started_on: 6.months.ago),
      ]
    end

    let(:mentor_induction_records) do
      [
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 2.years.ago, end_date: 9.months.ago),
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 9.months.ago),
      ]
    end

    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, mentor_at_school_periods:) }
    let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records) }

    it "can be initialized directly with teacher history classes" do
      expect(subject.user.trn).to eq(user.trn)
      expect(subject.user.full_name).to eql(user.full_name)
      expect(subject.ect.induction_records).to match_array(ect_induction_records)
      expect(subject.ect.mentor_at_school_periods).to match_array(mentor_at_school_periods)
      expect(subject.mentor.induction_records).to match_array(mentor_induction_records)
    end
  end

  describe "#build" do
    subject(:history) { described_class.build(teacher_profile:) }

    let(:ect_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
    let(:teacher_profile) { ect_profile.teacher_profile }
    let(:user) { teacher_profile.user }
    let(:school_cohort) { ect_profile.school_cohort }
    let(:induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort:) }
    let(:mentor_profile) { FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile:, school_cohort:) }
    let(:appropriate_body) { FactoryBot.create(:migration_appropriate_body) }
    let!(:ect_induction_records) do
      [
        FactoryBot.create(:migration_induction_record, :with_mentor, participant_profile: ect_profile, induction_programme:, appropriate_body:, start_date: 1.month.ago, end_date: 3.weeks.ago),
        FactoryBot.create(:migration_induction_record, :with_mentor, participant_profile: ect_profile, induction_programme:, appropriate_body:, start_date: 3.weeks.ago, end_date: nil)
      ]
    end

    let!(:mentor_at_school_periods) do
      school = FactoryBot.create(:school, urn: ect_induction_records.first.induction_programme.school_cohort.school.urn.to_i)
      period_1 = FactoryBot.create(:mentor_at_school_period,
                                   api_mentor_training_record_id: ect_induction_records.first.mentor_profile_id,
                                   school:)
      period_2 = FactoryBot.create(:mentor_at_school_period,
                                   api_mentor_training_record_id: ect_induction_records.last.mentor_profile_id,
                                   school:)
      [period_1, period_2]
    end

    let!(:mentor_induction_records) do
      [
        FactoryBot.create(:migration_induction_record, participant_profile: mentor_profile, induction_programme:, appropriate_body:, start_date: 1.month.ago, end_date: 3.weeks.ago),
        FactoryBot.create(:migration_induction_record, participant_profile: mentor_profile, induction_programme:, appropriate_body:, start_date: 3.weeks.ago, end_date: nil)
      ]
    end

    it "can be built with ECF1 data" do
      expect(history.user.trn).to eq(teacher_profile.trn)
      expect(history.user.full_name).to eq(user.full_name)
      expect(history.ect.participant_profile_id).to eq(ect_profile.id)
      expect(history.mentor.participant_profile_id).to eq(mentor_profile.id)
    end

    describe "ERO mentor attributes" do
      let(:state) { :payable }
      let!(:declaration) { FactoryBot.create(:migration_participant_declaration, participant_profile: mentor_profile, state:) }

      context "when the mentor did not participate in the ECF1 ERO phase" do
        it "the ero_mentor flag is not set" do
          expect(history.mentor.ero_mentor).to be_falsey
        end

        it "does not set the ero_declarations flag" do
          expect(history.mentor.ero_declarations).to be_falsey
        end
      end

      context "when the mentor participated in ECF1 ERO phase" do
        before do
          FactoryBot.create(:migration_ecf_ineligible_participant, trn: teacher_profile.trn)
        end

        it "sets the ero_mentor flag" do
          expect(history.mentor.ero_mentor).to be_truthy
        end

        context "when the mentor does not have any 'paid' or 'clawed_back' declarations" do
          it "does not set the ero_declarations flag" do
            expect(history.mentor.ero_declarations).to be_falsey
          end
        end

        context "when the mentor does have 'paid' declarations" do
          let(:state) { :paid }

          it "sets the ero_declarations flag" do
            expect(history.mentor.ero_declarations).to be_truthy
          end
        end

        context "when the mentor does have 'clawed_back' declarations" do
          let(:state) { :clawed_back }

          it "sets the ero_declarations flag" do
            expect(history.mentor.ero_declarations).to be_truthy
          end
        end
      end
    end

    describe "setting up induction records correctly" do
      describe "ECT induction records" do
        it "creates the right number" do
          expect(history.ect.induction_records.count).to eq ect_induction_records.count
        end

        it "populates the right attributes" do
          aggregate_failures "ECT induction records results" do
            ect_induction_records.each do |induction_record|
              historic_record = history.ect.induction_records.find { |hir| hir.induction_record_id == induction_record.id }
              expect(historic_record.start_date.to_date).to eq(induction_record.start_date.to_date)
              expect(historic_record.end_date&.to_date).to eq(induction_record&.end_date&.to_date)
              expect(historic_record.created_at).to be_within(1.second).of(induction_record.created_at)
              expect(historic_record.updated_at).to be_within(1.second).of(induction_record.updated_at)
              expect(historic_record.cohort_year).to eq(induction_record.schedule.cohort.start_year)
              expect(historic_record.school.urn).to eq(induction_record.induction_programme.school_cohort.school.urn)
              expect(historic_record.schedule_info.schedule_id).to eq(induction_record.schedule.id)
              expect(historic_record.schedule_info.name).to eq(induction_record.schedule.name)
              expect(historic_record.schedule_info.identifier).to eq(induction_record.schedule.schedule_identifier)
              expect(historic_record.schedule_info.cohort_year).to eq(induction_record.schedule.cohort.start_year)
              expect(historic_record.preferred_identity_email).to eq(induction_record.preferred_identity.email)
              expect(historic_record.mentor_profile_id).to eq(induction_record.mentor_profile_id)
              expect(historic_record.training_status).to eq(induction_record.training_status)
              expect(historic_record.induction_status).to eq(induction_record.induction_status)
              expect(historic_record.training_programme).to eq(induction_record.induction_programme.training_programme)
              expect(historic_record.training_provider_info.lead_provider_info.ecf1_id).to eq(induction_record.induction_programme.partnership.lead_provider_id)
              expect(historic_record.training_provider_info.lead_provider_info.name).to eq(induction_record.induction_programme.partnership.lead_provider.name)
              expect(historic_record.training_provider_info.delivery_partner_info.ecf1_id).to eq(induction_record.induction_programme.partnership.delivery_partner_id)
              expect(historic_record.training_provider_info.delivery_partner_info.name).to eq(induction_record.induction_programme.partnership.delivery_partner.name)
              expect(historic_record.training_provider_info.cohort_year).to eq(induction_record.induction_programme.partnership.cohort.start_year)
              expect(historic_record.appropriate_body.ecf1_id).to eq(induction_record.appropriate_body.id)
              expect(historic_record.appropriate_body.name).to eq(induction_record.appropriate_body.name)
            end
          end
        end
      end

      describe "ECT mentor at school periods" do
        it "creates the right number" do
          expect(history.ect.mentor_at_school_periods.count).to eq mentor_at_school_periods.count
        end

        it "populates the right attributes" do
          aggregate_failures "ECT mentor at school periods results" do
            mentor_at_school_periods.each do |mentor_at_school_period|
              historic_period = history.ect.mentor_at_school_periods.find { |hp| hp.mentor_at_school_period_id == mentor_at_school_period.id }
              expect(historic_period.started_on).to eq(mentor_at_school_period.started_on)
              expect(historic_period.finished_on).to eq(mentor_at_school_period&.finished_on)
              expect(historic_period.created_at).to be_within(1.second).of(mentor_at_school_period.created_at)
              expect(historic_period.updated_at).to be_within(1.second).of(mentor_at_school_period.updated_at)
              expect(historic_period.school.urn).to eq(mentor_at_school_period.school.urn.to_s)
              expect(historic_period.teacher.trn).to eq(mentor_at_school_period.teacher.trn)
              expect(historic_period.teacher.api_mentor_training_record_id).to eq(mentor_at_school_period.teacher.api_mentor_training_record_id)
            end
          end
        end
      end

      describe "Mentor induction records" do
        it "creates the right number" do
          expect(history.mentor.induction_records.count).to eq mentor_induction_records.count
        end

        it "populates the right attributes" do
          aggregate_failures "mentor induction records results" do
            mentor_induction_records.each do |induction_record|
              historic_record = history.mentor.induction_records.find { |ir| ir.induction_record_id == induction_record.id }
              expect(historic_record.start_date.to_date).to eq(induction_record.start_date.to_date)
              expect(historic_record.end_date&.to_date).to eq(induction_record.end_date&.to_date)
              expect(historic_record.created_at).to be_within(1.second).of(induction_record.created_at)
              expect(historic_record.updated_at).to be_within(1.second).of(induction_record.updated_at)
              expect(historic_record.cohort_year).to eq(induction_record.schedule.cohort.start_year)
              expect(historic_record.school.urn).to eq(induction_record.induction_programme.school_cohort.school.urn)
              expect(historic_record.schedule_info.schedule_id).to eq(induction_record.schedule.id)
              expect(historic_record.schedule_info.name).to eq(induction_record.schedule.name)
              expect(historic_record.schedule_info.identifier).to eq(induction_record.schedule.schedule_identifier)
              expect(historic_record.schedule_info.cohort_year).to eq(induction_record.schedule.cohort.start_year)
              expect(historic_record.preferred_identity_email).to eq(induction_record.preferred_identity.email)
              expect(historic_record.training_status).to eq(induction_record.training_status)
              expect(historic_record.induction_status).to eq(induction_record.induction_status)
              expect(historic_record.training_programme).to eq(induction_record.induction_programme.training_programme)
              expect(historic_record.training_provider_info.lead_provider_info.ecf1_id).to eq(induction_record.induction_programme.partnership.lead_provider_id)
              expect(historic_record.training_provider_info.lead_provider_info.name).to eq(induction_record.induction_programme.partnership.lead_provider.name)
              expect(historic_record.training_provider_info.delivery_partner_info.ecf1_id).to eq(induction_record.induction_programme.partnership.delivery_partner_id)
              expect(historic_record.training_provider_info.delivery_partner_info.name).to eq(induction_record.induction_programme.partnership.delivery_partner.name)
              expect(historic_record.training_provider_info.cohort_year).to eq(induction_record.induction_programme.partnership.cohort.start_year)
            end
          end
        end
      end
    end
  end
end
