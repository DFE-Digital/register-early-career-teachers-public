describe "One induction record" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2024 }
  # let(:lead_provider) { Types::LeadProvider.new(id: SecureRandom.uuid, name: "Lead Provider A") }
  # let(:delivery_partner) { Types::DeliveryPartner.new(id: SecureRandom.uuid, name: "Delivery Partner A") }

  let(:appropriate_body) { nil }

  let(:induction_record) do
    FactoryBot.build(:ecf1_teacher_history_induction_record_row, cohort_year:, appropriate_body:)
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
  end

  describe "ECT at school period attributes" do
    let(:ecf1_induction_record_row) { ecf1_teacher_history.ect.induction_records.first }
    let(:ecf2_ect_at_school_period_row) { subject.ect_at_school_period_rows.first }

    it "sets the URN from the induction record's induction programme" do
      expect(ecf2_ect_at_school_period_row.school.urn).to eql(ecf1_induction_record_row.school_urn)
    end

    it "sets the email address to the email from the induction record's preferred identity" do
      expect(ecf2_ect_at_school_period_row.email).to eql(ecf1_induction_record_row.preferred_identity_email)
    end

    describe "appropriate body" do
      context "when there is no appropriate body" do
        it "leaves appropriate body as nil" do
          expect(ecf2_ect_at_school_period_row.appropriate_body).to be_nil
        end
      end

      context "when there is an appropriate body" do
        let(:appropriate_body) { Types::AppropriateBodyData.new(id: SecureRandom.uuid, name: "Average Appropriate body") }

        it "sets the appropriate body to the one on the induction record" do
          expect(ecf2_ect_at_school_period_row.appropriate_body.id).to eql(ecf1_induction_record_row.appropriate_body.id)
          expect(ecf2_ect_at_school_period_row.appropriate_body.name).to eql(ecf1_induction_record_row.appropriate_body.name)
        end
      end
    end

    it "sets the start date to the induction record start date" do
      expect(ecf2_ect_at_school_period_row.started_on).to eql(ecf1_induction_record_row.start_date)
    end

    it "sets the end date to the induction record end date" do
      expect(ecf2_ect_at_school_period_row.finished_on).to eql(ecf1_induction_record_row.end_date)
    end

    describe "choosing the right started_on date" do
      context "when the induction record created_at is later than the start_date" do
        let(:induction_record) do
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, :created_at_later_than_start_date)
        end

        it "sets the start date to the induction record start date" do
          expect(ecf2_ect_at_school_period_row.started_on).to eql(ecf1_induction_record_row.start_date.to_date)
        end
      end

      context "when the induction record start date is later than the created_at" do
        let(:induction_record) do
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, :start_date_later_than_created_at)
        end

        it "sets the start date to the induction record created date" do
          expect(ecf2_ect_at_school_period_row.started_on).to eql(ecf1_induction_record_row.created_at.to_date)
        end
      end
    end
  end

  # Extra contexts:
  # * IR created_at date is later than the start_date
  # * with an school-reported AB
  # * deferred / withdrawn?
end
