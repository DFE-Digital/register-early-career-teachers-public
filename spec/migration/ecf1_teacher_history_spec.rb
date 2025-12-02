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

    let(:mentor_induction_records) do
      [
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 2.years.ago, end_date: 9.months.ago),
        FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 9.months.ago),
      ]
    end

    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records) }
    let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records) }

    it "can be initialized directly with teacher history classes" do
      expect(subject.user.trn).to eq(user.trn)
      expect(subject.user.full_name).to eql(user.full_name)
      expect(subject.ect.induction_records).to match_array(ect_induction_records)
      expect(subject.mentor.induction_records).to match_array(mentor_induction_records)
    end
  end

  describe "#build" do
    subject(:history) { described_class.build(teacher_profile:) }

    let(:ect_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
    let(:induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led) }
    let!(:ect_induction_records) { FactoryBot.create_list(:migration_induction_record, 2, participant_profile: ect_profile, induction_programme:) }
    let(:teacher_profile) { ect_profile.teacher_profile }
    let!(:user) { teacher_profile.user }
    let!(:mentor_profile) { FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile:) }
    let!(:mentor_induction_records) { FactoryBot.create_list(:migration_induction_record, 2, participant_profile: mentor_profile, induction_programme:) }

    it "can be built with ECF1 data" do
      expect(history.user.trn).to eq(teacher_profile.trn)
      expect(history.user.full_name).to eq(user.full_name)
      expect(history.ect.participant_profile_id).to eq(ect_profile.id)
      expect(history.mentor.participant_profile_id).to eq(mentor_profile.id)
    end

    describe "setting up induction records correctly" do
      describe "ECT induction records" do
        it "creates the right number" do
          expect(history.ect.induction_records.count).to eq ect_induction_records.count
        end

        it "populates the right attributes" do
          ect_induction_records.each do |induction_record|
            historic_record = history.ect.induction_records.find { |ir| ir.induction_record_id == induction_record.id }
            expect(historic_record.start_date).to eq(induction_record.start_date)
            expect(historic_record.end_date).to eq(induction_record.end_date)
            expect(historic_record.created_at).to eq(induction_record.created_at)
            expect(historic_record.updated_at).to eq(induction_record.updated_at)
            expect(historic_record.cohort_year).to eq(induction_record.schedule.cohort.start_year)
            expect(historic_record.school_urn).to eq(induction_record.induction_programme.school_cohort.school.urn)
            expect(historic_record.schedule.schedule_id).to eq(induction_record.schedule.id)
            expect(historic_record.schedule.name).to eq(induction_record.schedule.name)
            expect(historic_record.schedule.identifier).to eq(induction_record.schedule.schedule_identifier)
            expect(historic_record.schedule.cohort_year).to eq(induction_record.schedule.cohort.start_year)
            expect(historic_record.preferred_identity_email).to eq(induction_record.preferred_identity.email)
            expect(historic_record.mentor_profile_id).to eq(induction_record.mentor_profile_id)
            expect(historic_record.training_status).to eq(induction_record.training_status)
            expect(historic_record.induction_status).to eq(induction_record.induction_status)
            expect(historic_record.training_programme).to eq(induction_record.induction_programme.training_programme)
            expect(historic_record.training_provider_info.lead_provider_id).to eq(induction_record.induction_programme.partnership.lead_provider_id)
            expect(historic_record.training_provider_info.lead_provider_name).to eq(induction_record.induction_programme.partnership.lead_provider.name)
            expect(historic_record.training_provider_info.delivery_partner_id).to eq(induction_record.induction_programme.partnership.delivery_partner_id)
            expect(historic_record.training_provider_info.delivery_partner_name).to eq(induction_record.induction_programme.partnership.delivery_partner.name)
            expect(historic_record.training_provider_info.cohort_year).to eq(induction_record.induction_programme.partnership.cohort.start_year)
          end
        end
      end

      describe "Mentor induction records" do
        it "creates the right number" do
          expect(history.mentor.induction_records.count).to eq mentor_induction_records.count
        end

        it "populates the right attributes" do
          mentor_induction_records.each do |induction_record|
            historic_record = history.mentor.induction_records.find { |ir| ir.induction_record_id == induction_record.id }
            expect(historic_record.start_date).to eq(induction_record.start_date)
            expect(historic_record.end_date).to eq(induction_record.end_date)
            expect(historic_record.created_at).to eq(induction_record.created_at)
            expect(historic_record.updated_at).to eq(induction_record.updated_at)
            expect(historic_record.cohort_year).to eq(induction_record.schedule.cohort.start_year)
            expect(historic_record.school_urn).to eq(induction_record.induction_programme.school_cohort.school.urn)
            expect(historic_record.schedule.schedule_id).to eq(induction_record.schedule.id)
            expect(historic_record.schedule.name).to eq(induction_record.schedule.name)
            expect(historic_record.schedule.identifier).to eq(induction_record.schedule.schedule_identifier)
            expect(historic_record.schedule.cohort_year).to eq(induction_record.schedule.cohort.start_year)
            expect(historic_record.preferred_identity_email).to eq(induction_record.preferred_identity.email)
            expect(historic_record.training_status).to eq(induction_record.training_status)
            expect(historic_record.induction_status).to eq(induction_record.induction_status)
            expect(historic_record.training_programme).to eq(induction_record.induction_programme.training_programme)
            expect(historic_record.training_provider_info.lead_provider_id).to eq(induction_record.induction_programme.partnership.lead_provider_id)
            expect(historic_record.training_provider_info.lead_provider_name).to eq(induction_record.induction_programme.partnership.lead_provider.name)
            expect(historic_record.training_provider_info.delivery_partner_id).to eq(induction_record.induction_programme.partnership.delivery_partner_id)
            expect(historic_record.training_provider_info.delivery_partner_name).to eq(induction_record.induction_programme.partnership.delivery_partner.name)
            expect(historic_record.training_provider_info.cohort_year).to eq(induction_record.induction_programme.partnership.cohort.start_year)
          end
        end
      end
    end
  end
end
