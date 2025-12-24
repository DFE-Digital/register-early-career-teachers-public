describe "Migrating a teacher record" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2024 }

  let(:training_status) { "active" }
  let(:appropriate_body) { nil }
  let(:lead_provider_info) { nil }
  let(:delivery_partner_info) { nil }
  let(:training_programme) { nil }
  let(:schedule_info) { nil }
  let(:training_provider_info) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year:, lead_provider_info:, delivery_partner_info:) }

  let(:induction_record) do
    FactoryBot.build(
      :ecf1_teacher_history_induction_record_row,
      cohort_year:,
      appropriate_body:,
      training_programme:,
      training_status:,
      training_provider_info:,
      schedule_info:
    )
  end

  let(:ecf1_teacher_history) do
    FactoryBot.build(:ecf1_teacher_history) do |history|
      history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
        ect.induction_records = [induction_record]
      end
    end
  end

  describe "teacher attributes" do
    it "sets the TRN from the teacher profile" do
      expect(subject.teacher_row.trn).to eql(ecf1_teacher_history.user.trn)
    end

    it "sets the first and last name from the user" do
      first_name, last_name = *ecf1_teacher_history.user.full_name.split

      aggregate_failures do
        expect(subject.teacher_row.trs_first_name).to eql(first_name)
        expect(subject.teacher_row.trs_last_name).to eql(last_name)
      end
    end

    it "sets the api_id to the user_id" do
      expect(subject.teacher_row.api_id).to eql(ecf1_teacher_history.user.user_id)
    end

    it "set the created and updated timestamps from the user" do
      aggregate_failures do
        expect(subject.teacher_row.created_at).to be_within(1.second).of(ecf1_teacher_history.user.created_at)
        expect(subject.teacher_row.updated_at).to be_within(1.second).of(ecf1_teacher_history.user.updated_at)
      end
    end

    it "sets the api updated at timestamp to the latest value from the teacher" do
      latest_updated_at = [
        ecf1_teacher_history.user.updated_at,
        ecf1_teacher_history.ect.updated_at,
        *ecf1_teacher_history.ect.induction_records.map(&:updated_at),
      ].max

      expect(subject.teacher_row.api_updated_at).to be_within(1.second).of(latest_updated_at)
    end
  end
end
