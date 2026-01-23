class FakeTeacherHistoryConverter
  include TeacherHistoryConverter::CalculatedAttributes

  def migration_mode = :latest_induction_records
end

describe TeacherHistoryConverter::CalculatedAttributes do
  describe "#latest_induction_records" do
    subject { FakeTeacherHistoryConverter.new.latest_induction_records(induction_records:) }

    let(:school_1) { Types::SchoolData.new(urn: 111_111, name: "School 1") }
    let(:school_2) { Types::SchoolData.new(urn: 222_222, name: "School 2") }
    let(:school_3) { Types::SchoolData.new(urn: 333_333, name: "School 3") }
    let(:provider_1_2022) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year: 2022) }
    let(:provider_2_2022) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year: 2022) }
    let(:provider_3_2022) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year: 2022) }
    let(:provider_3_2024) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year: 2024) }

    let(:ir_school_1_registration) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_1,
                       training_provider_info: provider_1_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2023, 5, 1),
                       end_date: Date.new(2022, 10, 1),
                       created_at: Time.zone.local(2022, 9, 1))
    end

    let(:ir_school_1_start_date_update) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_1,
                       training_provider_info: provider_1_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2022, 9, 1),
                       end_date: Date.new(2022, 11, 1),
                       created_at: Time.zone.local(2022, 10, 1))
    end

    let(:ir_school_2_transfer) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_2,
                       training_provider_info: provider_2_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2022, 8, 1),
                       end_date: Date.new(2022, 12, 1),
                       created_at: Time.zone.local(2022, 11, 1))
    end

    let(:ir_school_2_leaving_2023_1_1) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_2,
                       training_provider_info: provider_2_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2022, 12, 1),
                       end_date: Date.new(2023, 3, 1),
                       created_at: Time.zone.local(2022, 12, 1))
    end

    let(:ir_school_3_transfer) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_3,
                       training_provider_info: provider_2_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2023, 1, 1),
                       end_date: Date.new(2023, 2, 1),
                       created_at: Time.zone.local(2023, 1, 1))
    end

    let(:ir_school_3_provider_change) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_3,
                       training_provider_info: provider_3_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2023, 2, 1),
                       end_date: Date.new(2025, 10, 1),
                       created_at: Time.zone.local(2023, 2, 1))
    end

    let(:ir_school_2_provider_2_withdrawal) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_2,
                       training_provider_info: provider_2_2022,
                       cohort_year: 2022,
                       start_date: Date.new(2023, 3, 1),
                       end_date: Date.new(2023, 1, 1),
                       created_at: Time.zone.local(2023, 3, 1))
    end

    let(:ir_school_3_cohort_change_ongoing) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                       school: school_3,
                       training_provider_info: provider_3_2024,
                       cohort_year: 2024,
                       start_date: Date.new(2025, 10, 1),
                       end_date: nil,
                       created_at: Time.zone.local(2025, 10, 1))
    end

    let(:induction_records) do
      [
        ir_school_1_registration,
        ir_school_1_start_date_update,
        ir_school_2_transfer,
        ir_school_2_leaving_2023_1_1,
        ir_school_2_provider_2_withdrawal,
        ir_school_3_transfer,
        ir_school_3_provider_change,
        ir_school_3_cohort_change_ongoing
      ]
    end

    let(:result) do
      [
        ir_school_1_start_date_update,
        ir_school_3_transfer,
        ir_school_3_provider_change,
        ir_school_2_provider_2_withdrawal,
        ir_school_3_cohort_change_ongoing
      ]
    end

    it { is_expected.to match_array(result) }
  end

  describe "#participant_api_updated_at" do
    subject { FakeTeacherHistoryConverter.new.participant_api_updated_at(ecf1_teacher_history:) }

    let(:short_time_ago) { 3.months.ago }
    let(:long_time_ago) { 6.months.ago }

    let(:user_updated_at) { long_time_ago }
    let(:ect_updated_at) { long_time_ago }
    let(:ect_induction_record_updated_at) { long_time_ago }
    let(:mentor_updated_at) { long_time_ago }
    let(:mentor_induction_record_updated_at) { long_time_ago }
    let(:participant_identity_updated_ats) { [long_time_ago, long_time_ago] }

    let(:ecf1_teacher_history_user) { FactoryBot.build(:ecf1_teacher_history_user, updated_at: user_updated_at) }

    let(:ecf1_teacher_history) do
      FactoryBot.build(:ecf1_teacher_history, user: ecf1_teacher_history_user, participant_identity_updated_ats:) do |history|
        history.ect = FactoryBot.build(:ecf1_teacher_history_ect, updated_at: ect_updated_at) do |ect|
          ect.induction_records = [
            FactoryBot.build(:ecf1_teacher_history_induction_record_row, updated_at: ect_induction_record_updated_at)
          ]
        end
        history.mentor = FactoryBot.build(:ecf1_teacher_history_mentor, updated_at: mentor_updated_at) do |mentor|
          mentor.induction_records = [
            FactoryBot.build(:ecf1_teacher_history_induction_record_row, updated_at: mentor_induction_record_updated_at)
          ]
        end
      end
    end

    context "when the user record was updated most recently" do
      let(:user_updated_at) { short_time_ago }

      it "selects the user updated at timestamp" do
        freeze_time { expect(subject).to eql(user_updated_at) }
      end
    end

    context "when the ECT participant profile was updated most recently" do
      let(:ect_updated_at) { short_time_ago }

      it "selects the ECT participant profile timestamp" do
        freeze_time { expect(subject).to eql(ect_updated_at) }
      end
    end

    context "when an ECT induction record was updated most recently" do
      let(:ect_induction_record_updated_at) { short_time_ago }

      it "selects the ECT induction record timestamp" do
        freeze_time { expect(subject).to eql(ect_induction_record_updated_at) }
      end
    end

    context "when the mentor participant profile was most recently" do
      let(:mentor_updated_at) { short_time_ago }

      it "selects the mentor participant profile timestamp" do
        freeze_time { expect(subject).to eql(mentor_updated_at) }
      end
    end

    context "when the mentor induction record was most recently" do
      let(:mentor_induction_record_updated_at) { short_time_ago }

      it "selects the mentor induction record timestamp" do
        freeze_time { expect(subject).to eql(mentor_induction_record_updated_at) }
      end
    end

    context "when a participant identity was updated most recently" do
      let(:participant_identity_updated_ats) { [long_time_ago, short_time_ago] }

      it "selects the mentor induction record timestamp" do
        freeze_time { expect(subject).to eql(short_time_ago) }
      end
    end
  end

  describe "#convert_training_programme_name" do
    subject { FakeTeacherHistoryConverter.new.convert_training_programme_name(training_programme) }

    context "when the ecf1 training programme is full_induction_programme" do
      let(:training_programme) { "full_induction_programme" }

      it "returns 'provider_led'" do
        expect(subject).to eq "provider_led"
      end
    end

    context "when the ecf1 training programme is core_induction_programme" do
      let(:training_programme) { "core_induction_programme" }

      it "returns 'school_led'" do
        expect(subject).to eq "school_led"
      end
    end

    context "when the ecf1 training programme is design_our_own" do
      let(:training_programme) { "design_our_own" }

      it "returns 'school_led'" do
        expect(subject).to eq "school_led"
      end
    end

    context "when the ecf1 training programme is school_funded_fip" do
      let(:training_programme) { "school_funded_fip" }

      it "returns 'provider_led'" do
        expect(subject).to eq "provider_led"
      end
    end
  end
end
