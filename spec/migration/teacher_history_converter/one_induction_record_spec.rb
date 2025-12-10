describe "One induction record" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2024 }

  let(:training_status) { "active" }
  let(:appropriate_body) { nil }
  let(:lead_provider) { nil }
  let(:delivery_partner) { nil }
  let(:training_programme) { nil }
  let(:schedule_info) { nil }
  let(:training_provider_info) { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year:, lead_provider:, delivery_partner:) }

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

    describe "end date" do
      context "when there is an end date" do
        it "sets the end date to the induction record end date" do
          expect(ecf2_ect_at_school_period_row.finished_on).to eql(ecf1_induction_record_row.end_date)
        end
      end

      context "when there is no end date" do
        let(:induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :ongoing, cohort_year:) }

        it "leaves the end date nil" do
          expect(ecf2_ect_at_school_period_row.finished_on).to be_nil
        end
      end
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

  describe "Training period attributes" do
    let(:ecf1_induction_record_row) { ecf1_teacher_history.ect.induction_records.first }
    let(:ecf2_ect_at_school_period_row) { subject.ect_at_school_period_rows.first }
    let(:ecf2_training_period_row) { ecf2_ect_at_school_period_row.training_period_rows.first }

    it "sets the start date to the induction record start date" do
      expect(ecf2_training_period_row.started_on).to eql(ecf1_induction_record_row.start_date)
    end

    describe "end date" do
      context "when there is an end date" do
        it "sets the end date to the induction record end date" do
          expect(ecf2_training_period_row.finished_on).to eql(ecf1_induction_record_row.end_date)
        end
      end

      context "when there is no end date" do
        let(:induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :ongoing, cohort_year:) }

        it "leaves the end date nil" do
          expect(ecf2_training_period_row.finished_on).to be_nil
        end
      end
    end

    describe "choosing the right started_on date" do
      context "when the induction record created_at is later than the start_date" do
        let(:induction_record) do
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, :created_at_later_than_start_date)
        end

        it "sets the start date to the induction record start date" do
          expect(ecf2_training_period_row.started_on).to eql(ecf1_induction_record_row.start_date.to_date)
        end
      end

      context "when the induction record start date is later than the created_at" do
        let(:induction_record) do
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, :start_date_later_than_created_at)
        end

        it "sets the start date to the induction record created date" do
          expect(ecf2_training_period_row.started_on).to eql(ecf1_induction_record_row.created_at.to_date)
        end
      end
    end

    describe "training programme" do
      context "when training programme is :core_induction_programme" do
        let(:training_programme) { :core_induction_programme }

        it "sets the training programme to school_led" do
          expect(ecf2_training_period_row.training_programme).to eql("school_led")
        end
      end

      context "when training programme is :design_our_own" do
        let(:training_programme) { :design_our_own }

        it "sets the training programme to school_led" do
          expect(ecf2_training_period_row.training_programme).to eql("school_led")
        end
      end

      context "when training programme is :school_funded_fip" do
        let(:training_programme) { :school_funded_fip }

        it "sets the training programme to provider_led" do
          expect(ecf2_training_period_row.training_programme).to eql("provider_led")
        end
      end

      context "when training programme is :full_induction_programme" do
        let(:training_programme) { :full_induction_programme }

        it "sets the training programme to provider_led" do
          expect(ecf2_training_period_row.training_programme).to eql("provider_led")
        end
      end
    end

    describe "deferred" do
      context "when training state is deferred" do
        let(:training_status) { "deferred" }

        it "sets the deferred at timestamp" do
          expect(ecf2_training_period_row.deferred_at).to eql(ecf1_induction_record_row.end_date)
        end

        it "leaves the withdrawn at timestamp blank" do
          expect(ecf2_training_period_row.withdrawn_at).to be_nil
        end

        describe "deferral reasons" do
          it "sets the deferral reason" do
            pending "we need to find the relevant record from participant_profile_states"

            expect(ecf2_training_period_row.deferral_reason).to eql(ecf2_training_period_row.finished_on)
          end

          # bereavement
          # long-term-sickness
          # parental-leave
          # career-break
          # other
        end
      end
    end

    describe "withdrawn" do
      context "when training state is deferred" do
        let(:training_status) { "withdrawn" }

        it "sets the withdrawn at timestamp" do
          expect(ecf2_training_period_row.withdrawn_at).to eql(ecf1_induction_record_row.end_date)
        end

        it "leaves the deferred at timestamp blank" do
          expect(ecf2_training_period_row.deferred_at).to be_nil
        end

        describe "withdrawal reasons" do
          it "sets the withdrawal reason" do
            pending "we need to find the relevant record from participant_profile_states"

            expect(ecf2_training_period_row.withdrawal_reason).to eql(ecf2_training_period_row.finished_on)
          end

          # left-teaching-profession
          # moved-school
          # mentor-no-longer-being-mentor
          # school-left-fip
          # other
        end
      end
    end

    describe "lead providers and delivery partners" do
      let(:lead_provider) { Types::LeadProvider.new(id: SecureRandom.uuid, name: "Lead Provider A") }
      let(:delivery_partner) { Types::DeliveryPartner.new(id: SecureRandom.uuid, name: "Delivery Partner A") }

      it "sets the lead provider to the one in the training period info" do
        expect(ecf2_training_period_row.lead_provider).to eql(ecf1_induction_record_row.training_provider_info.lead_provider)
      end

      it "sets the delivery partner to the one in the training period info" do
        expect(ecf2_training_period_row.delivery_partner).to eql(ecf1_induction_record_row.training_provider_info.delivery_partner)
      end
    end

    describe "schedules" do
      context "when there is no schedule" do
        it "leaves the schedule blank" do
          expect(ecf2_training_period_row.schedule_info).to be_nil
        end
      end

      context "when there is a schedule" do
        let(:schedule) { FactoryBot.build(:ecf1_teacher_history_schedule_info) }

        it "sets the schedule to the one from the induction record" do
          expect(ecf2_training_period_row.schedule_info).to eql(ecf1_induction_record_row.schedule_info)
        end
      end
    end
  end
end
