describe API::TeacherSerializer, :with_metadata, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(teacher, **options))
  end

  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }

  before do
    # Ensure other metadata exists for another lead provider.
    FactoryBot.create(:lead_provider)
  end

  describe "core attributes" do
    it "serializes `id`" do
      expect(response["id"]).to eq(teacher.api_id)
    end

    it "serializes `type`" do
      expect(response["type"]).to eq("participant")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes `full_name`" do
      expect(attributes["full_name"]).to eq(Teachers::Name.new(teacher).full_name_in_trs)
    end

    it "serializes `updated_at`" do
      expect(attributes["updated_at"]).to eq(teacher.updated_at.utc.rfc3339)
    end

    it "serializes `teacher_reference_number`" do
      expect(attributes["teacher_reference_number"]).to eq(teacher.trn)
    end

    describe "participant_id_changes" do
      subject(:participant_id_changes) { response["attributes"]["participant_id_changes"] }

      it { is_expected.to be_empty }

      context "when there are teacher_id_changes" do
        let!(:teacher_id_change_1) { travel_to(2.days.ago) { FactoryBot.create(:teacher_id_change, teacher:) } }
        let!(:teacher_id_change_2) { FactoryBot.create(:teacher_id_change, teacher:) }

        it { expect(participant_id_changes.count).to eq(2) }

        it "serializes `from_participant_id`" do
          expect(participant_id_changes[0]["from_participant_id"]).to eq(teacher_id_change_1.api_from_teacher_id)
          expect(participant_id_changes[1]["from_participant_id"]).to eq(teacher_id_change_2.api_from_teacher_id)
        end

        it "serializes `to_participant_id`" do
          expect(participant_id_changes[0]["to_participant_id"]).to eq(teacher_id_change_1.api_to_teacher_id)
          expect(participant_id_changes[1]["to_participant_id"]).to eq(teacher_id_change_2.api_to_teacher_id)
        end

        it "serializes `changed_at`" do
          expect(participant_id_changes[0]["changed_at"]).to eq(teacher_id_change_1.created_at.utc.rfc3339)
          expect(participant_id_changes[1]["changed_at"]).to eq(teacher_id_change_2.created_at.utc.rfc3339)
        end
      end
    end

    describe "ecf_enrolments" do
      subject(:ecf_enrolments) { response["attributes"]["ecf_enrolments"] }

      it { is_expected.to be_empty }

      context "when there are ECT/mentor training periods for the lead provider" do
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, lead_provider:) }

        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: 2.months.ago, finished_on: nil) }
        let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period:, lead_provider_delivery_partnership:) }

        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: 2.months.ago, finished_on: nil) }
        let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period:, lead_provider_delivery_partnership:) }

        let(:other_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 2.months.ago, finished_on: nil) }
        let!(:other_mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: other_mentor_at_school_period, lead_provider_delivery_partnership:) }

        let!(:latest_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: other_mentor_at_school_period,
            started_on: ect_training_period.started_on + 1.week,
            finished_on: nil
          )
        end

        it { expect(ecf_enrolments.count).to eq(2) }

        describe "ECT enrolment" do
          subject(:ect_enrolment) { response["attributes"]["ecf_enrolments"][0] }

          it "serializes `training_record_id`" do
            expect(ect_enrolment["training_record_id"]).to eq(teacher.api_ect_training_record_id)
          end

          it "serializes `email`" do
            expect(ect_enrolment["email"]).to eq(ect_at_school_period.email)
          end

          it "serializes `mentor_id`" do
            expect(ect_enrolment["mentor_id"]).to eq(latest_mentorship_period.mentor.teacher.api_id)
          end

          context "when there is no latest mentor training period" do
            let(:latest_mentorship_period) { nil }

            it "serializes `mentor_id` as nil" do
              expect(ect_enrolment["mentor_id"]).to be_nil
            end
          end

          it "serializes `school_urn`" do
            expect(ect_enrolment["school_urn"]).to eq(ect_training_period.school_partnership.school.urn)
          end

          it "serializes `participant_type`" do
            expect(ect_enrolment["participant_type"]).to eq("ect")
          end

          it "serializes `cohort`" do
            expect(ect_enrolment["cohort"]).to eq(ect_training_period.school_partnership.contract_period.year)
          end

          it "serializes `training_status`" do
            expect(ect_enrolment["training_status"]).to eq("active")
          end

          it "serializes `participant_status`" do
            expect(ect_enrolment["participant_status"]).to eq("active")
          end

          it "serializes `eligible_for_funding`" do
            expect(ect_enrolment["eligible_for_funding"]).to be(true)
          end

          it "serializes `pupil_premium_uplift`" do
            expect(ect_enrolment["pupil_premium_uplift"]).to eq(teacher.ect_pupil_premium_uplift)
          end

          it "serializes `sparsity_uplift`" do
            expect(ect_enrolment["sparsity_uplift"]).to eq(teacher.ect_sparsity_uplift)
          end

          it "serializes `schedule_identifier`" do
            expect(ect_enrolment["schedule_identifier"]).to eq("ecf-extended-september")
          end

          it "serializes `delivery_partner_id`" do
            expect(ect_enrolment["delivery_partner_id"]).to eq(ect_training_period.school_partnership.delivery_partner.api_id)
          end

          it "serializes `withdrawal`" do
            expect(ect_enrolment["withdrawal"]).to be_nil
          end

          it "serializes `deferral`" do
            expect(ect_enrolment["deferral"]).to be_nil
          end

          it "serializes `created_at`" do
            expect(ect_enrolment["created_at"]).to eq(teacher.earliest_ect_at_school_period.created_at.utc.rfc3339)
          end

          it "serializes `induction_end_date`" do
            finished_induction_period = FactoryBot.create(:induction_period, :pass, teacher:)
            expect(ect_enrolment["induction_end_date"]).to eq(finished_induction_period.finished_on.rfc3339)
          end

          context "when there is no finished induction period" do
            it "serializes `induction_end_date` as nil" do
              expect(ect_enrolment["induction_end_date"]).to be_nil
            end
          end

          it "serializes `overall_induction_start_date`" do
            started_induction_period = FactoryBot.create(:induction_period, :ongoing, teacher:)
            expect(ect_enrolment["overall_induction_start_date"]).to eq(started_induction_period.started_on.rfc3339)
          end

          context "when there is no started induction period" do
            it "serializes `overall_induction_start_date` as nil" do
              expect(ect_enrolment["overall_induction_start_date"]).to be_nil
            end
          end

          it "serializes `mentor_funding_end_date`" do
            expect(ect_enrolment["mentor_funding_end_date"]).to be_nil
          end

          it "serializes `mentor_became_ineligible_for_funding_reason`" do
            expect(ect_enrolment["mentor_became_ineligible_for_funding_reason"]).to be_nil
          end

          it "serializes `cohort_changed_after_payments_frozen`" do
            expect(ect_enrolment["cohort_changed_after_payments_frozen"]).to eq(teacher.ect_payments_frozen_year.present?)
          end
        end

        describe "mentor enrolment" do
          subject(:mentor_enrolment) { response["attributes"]["ecf_enrolments"][1] }

          it "serializes `training_record_id`" do
            expect(mentor_enrolment["training_record_id"]).to eq(teacher.api_mentor_training_record_id)
          end

          it "serializes `email`" do
            expect(mentor_enrolment["email"]).to eq(mentor_at_school_period.email)
          end

          it "serializes `mentor_id`" do
            expect(mentor_enrolment["mentor_id"]).to be_nil
          end

          it "serializes `school_urn`" do
            expect(mentor_enrolment["school_urn"]).to eq(mentor_training_period.school_partnership.school.urn)
          end

          it "serializes `participant_type`" do
            expect(mentor_enrolment["participant_type"]).to eq("mentor")
          end

          it "serializes `cohort`" do
            expect(mentor_enrolment["cohort"]).to eq(mentor_training_period.school_partnership.contract_period.year)
          end

          it "serializes `training_status`" do
            expect(mentor_enrolment["training_status"]).to eq("active")
          end

          it "serializes `participant_status`" do
            expect(mentor_enrolment["participant_status"]).to eq("active")
          end

          it "serializes `eligible_for_funding`" do
            expect(mentor_enrolment["eligible_for_funding"]).to be(true)
          end

          it "serializes `pupil_premium_uplift`" do
            expect(mentor_enrolment["pupil_premium_uplift"]).to be(false)
          end

          it "serializes `sparsity_uplift`" do
            expect(mentor_enrolment["sparsity_uplift"]).to be(false)
          end

          it "serializes `schedule_identifier`" do
            expect(mentor_enrolment["schedule_identifier"]).to eq("ecf-extended-september")
          end

          it "serializes `delivery_partner_id`" do
            expect(mentor_enrolment["delivery_partner_id"]).to eq(mentor_training_period.school_partnership.delivery_partner.api_id)
          end

          it "serializes `withdrawal`" do
            expect(mentor_enrolment["withdrawal"]).to be_nil
          end

          it "serializes `deferral`" do
            expect(mentor_enrolment["deferral"]).to be_nil
          end

          it "serializes `created_at`" do
            expect(mentor_enrolment["created_at"]).to eq(teacher.earliest_mentor_at_school_period.created_at.utc.rfc3339)
          end

          it "serializes `induction_end_date`" do
            finished_induction_period = FactoryBot.create(:induction_period, :pass, teacher:)
            expect(mentor_enrolment["induction_end_date"]).to eq(finished_induction_period.finished_on.rfc3339)
          end

          context "when there is no finished induction period" do
            it "serializes `induction_end_date` as nil" do
              expect(mentor_enrolment["induction_end_date"]).to be_nil
            end
          end

          it "serializes `overall_induction_start_date`" do
            started_induction_period = FactoryBot.create(:induction_period, :ongoing, teacher:)
            expect(mentor_enrolment["overall_induction_start_date"]).to eq(started_induction_period.started_on.rfc3339)
          end

          context "when there is no started induction period" do
            it "serializes `overall_induction_start_date` as nil" do
              expect(mentor_enrolment["overall_induction_start_date"]).to be_nil
            end
          end

          it "serializes `mentor_funding_end_date`" do
            expect(mentor_enrolment["mentor_funding_end_date"]).to eq(teacher.mentor_became_ineligible_for_funding_on.rfc3339)
          end

          context "when there is no `mentor_funding_end_date`" do
            before { teacher.update!(mentor_became_ineligible_for_funding_on: nil, mentor_became_ineligible_for_funding_reason: nil) }

            it "serializes `mentor_funding_end_date` as nil" do
              expect(mentor_enrolment["mentor_funding_end_date"]).to be_nil
            end
          end

          it "serializes `mentor_ineligible_for_funding_reason`" do
            expect(mentor_enrolment["mentor_ineligible_for_funding_reason"]).to eq(teacher.mentor_became_ineligible_for_funding_reason)
          end

          it "serializes `cohort_changed_after_payments_frozen`" do
            expect(mentor_enrolment["cohort_changed_after_payments_frozen"]).to eq(teacher.mentor_payments_frozen_year.present?)
          end
        end
      end
    end
  end
end
