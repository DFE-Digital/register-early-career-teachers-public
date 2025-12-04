describe "One induction record" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2024 }
  let(:schedule) { FactoryBot.build(:ecf1_teacher_history_schedule_info, cohort_year:) }

  let(:lead_provider) do
    Types::LeadProvider.new(id: SecureRandom.uuid,
                            name: "Lead Provider A")
  end

  let(:delivery_partner) do
    Types::DeliveryPartner.new(id: SecureRandom.uuid,
                               name: "Delivery Partner A")
  end

  let(:ecf1_ect) { FactoryBot.build(:ecf1_teacher_history_ect) }

  let(:ecf1_teacher_history) do
    FactoryBot.build(:ecf1_teacher_history) do |history|
      history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
        ect.induction_records = [
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            cohort_year:,
            training_provider_info: FactoryBot.build(
              :ecf1_teacher_history_training_provider_info,
              lead_provider:,
              delivery_partner:
            )
          )
        ]
      end
    end
  end

  describe "teacher attributes" do
    it "sets the right TRN" do
      expect(subject.teacher_row.trn).to eql(ecf1_teacher_history.user.trn)
    end

    it "sets the right first and last name" do
      first_name, last_name = *ecf1_teacher_history.user.full_name.split

      aggregate_failures do
        expect(subject.teacher_row.trs_first_name).to eql(first_name)
        expect(subject.teacher_row.trs_last_name).to eql(last_name)
      end
    end

    it "set the right api_id" do
      expect(subject.teacher_row.api_id).to eql(ecf1_teacher_history.user.user_id)
    end

    it "set the right timestamps" do
      skip "not implemented yet"

      aggregate_failures do
        expect(subject.teacher_row.created_at).to eql(ecf1_teacher_history.user.created_at)
        expect(subject.teacher_row.updated_at).to eql(ecf1_teacher_history.user.updated_at)
      end
    end
  end

  describe "ECT at school period attributes" do
    let(:ecf1_induction_record_row) { ecf1_teacher_history.ect.induction_records.first }
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
