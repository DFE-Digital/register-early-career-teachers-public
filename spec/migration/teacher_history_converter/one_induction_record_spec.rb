describe "One induction record" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:ecf1_user) do
    FactoryBot.build(
      :ecf1_teacher_history_user,
      trn: "1234567",
      full_name: "Bob Carolgees"
    )
  end

  let(:cohort_year) { 2024 }
  let(:schedule) { FactoryBot.build(:ecf1_teacher_history_schedule_info, cohort_year:) }

  let(:lead_provider_id) { SecureRandom.uuid }
  let(:lead_provider_name) { "Lead Provider A" }
  let(:delivery_partner_id) { SecureRandom.uuid }
  let(:delivery_partner_name) { "Delivery Partner A" }

  let(:ecf1_ect) do
    FactoryBot.build(
      :ecf1_teacher_history_ect,
      induction_records: [
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2024, 1, 1),
          end_date: nil,
          induction_status: "active",
          training_status: "active",
          mentor_profile_id: nil,
          cohort_year:,
          schedule:,
          school_urn: 123_456,
          training_provider_info: FactoryBot.build(
            :ecf1_teacher_history_training_provider_info,
            cohort_year:,
            lead_provider_id:,
            lead_provider_name:,
            delivery_partner_id:,
            delivery_partner_name:
          )
        )
      ]
    )
  end

  let(:ecf1_teacher_history) do
    ECF1TeacherHistory.new(user: ecf1_user, ect: ecf1_ect)
  end

  describe "teacher attributes" do
    it "sets the right TRN" do
      expect(subject.teacher_row.trn).to eql(ecf1_user.trn)
    end

    it "sets the right first name" do
      expect(subject.teacher_row.trs_first_name).to eql("Bob")
    end

    it "sets the right last name" do
      expect(subject.teacher_row.trs_last_name).to eql("Carolgees")
    end

    it "set the right api_id" do
      expect(subject.teacher_row.api_id).to eql(ecf1_user.user_id)
    end

    pending "set the right timestamps" # will be teacher.updated_at/created_at
  end

  describe "ECT at school period attributes" do
    let(:ecf1_induction_record_row) { ecf1_ect.induction_records.first }
    let(:ecf2_ect_at_school_period_row) { subject.ect_at_school_period_rows.first }

    it "sets the right URN" do
      expect(ecf2_ect_at_school_period_row.school.urn).to eql(ecf1_induction_record_row.school_urn)
    end

    it "sets the right email address" do
      expect(ecf2_ect_at_school_period_row.email).to eql(ecf1_induction_record_row.preferred_identity_email)
    end

    it "leaves appropriate body as nil" do
      expect(ecf2_ect_at_school_period_row.appropriate_body).to be_nil
    end

    it "sets the right start date" do
      expect(ecf2_ect_at_school_period_row.started_on).to eql(ecf1_induction_record_row.start_date)
    end

    it "sets the right end date" do
      expect(ecf2_ect_at_school_period_row.finished_on).to eql(ecf1_induction_record_row.end_date)
    end
  end
end
