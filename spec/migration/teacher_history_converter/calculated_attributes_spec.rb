class FakeTeacherHistoryConverter
  include TeacherHistoryConverter::CalculatedAttributes

  def migration_mode = :latest_induction_records
end

describe TeacherHistoryConverter::CalculatedAttributes do
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
