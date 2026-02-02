describe API::TeacherSerializer, :with_metadata, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(teacher, **options))
  end

  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }
  let(:teacher) do
    FactoryBot.create(
      :teacher,
      :with_sparsity_uplift,
      :with_pupil_premium_uplift,
      :ineligible_for_mentor_funding,
      api_ect_training_record_id: SecureRandom.uuid,
      api_mentor_training_record_id: SecureRandom.uuid,
      api_updated_at:
    )
  end

  before do
    # Ensure other metadata exists for another lead provider.
    FactoryBot.create(:lead_provider)
  end

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to be_present
      expect(response["id"]).to eq(teacher.api_id)
      expect(response["type"]).to eq("participant")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["updated_at"]).to be_present
      expect(attributes["updated_at"]).to eq(api_updated_at.utc.rfc3339)
      expect(attributes["teacher_reference_number"]).to be_present
      expect(attributes["teacher_reference_number"]).to eq(teacher.trn)
    end

    describe "`full_name`" do
      subject(:full_name) { attributes["full_name"] }

      it { is_expected.to be_present }
      it { is_expected.to eq(Teachers::Name.new(teacher).full_name) }

      context "when teacher has a `corrected_name`" do
        let(:teacher) { FactoryBot.create(:teacher, :with_corrected_name) }

        it { is_expected.to eq(teacher.corrected_name) }
      end

      context "when teacher has a `full_name_in_trs`" do
        let(:teacher) { FactoryBot.create(:teacher, :with_realistic_name) }

        it { is_expected.to eq([teacher.trs_first_name, teacher.trs_last_name].join(" ")) }
      end
    end

    describe "participant_id_changes" do
      subject(:participant_id_changes) { response["attributes"]["participant_id_changes"] }

      it { is_expected.to be_empty }

      context "when there are teacher_id_changes" do
        let!(:teacher_id_change_1) { travel_to(2.days.ago) { FactoryBot.create(:teacher_id_change, teacher:) } }
        let!(:teacher_id_change_2) { FactoryBot.create(:teacher_id_change, teacher:) }

        it "serializes correctly" do
          expect(participant_id_changes.count).to eq(2)

          expect(participant_id_changes[0]["from_participant_id"]).to be_present
          expect(participant_id_changes[0]["from_participant_id"]).to eq(teacher_id_change_1.api_from_teacher_id)
          expect(participant_id_changes[0]["to_participant_id"]).to be_present
          expect(participant_id_changes[0]["to_participant_id"]).to eq(teacher_id_change_1.api_to_teacher_id)
          expect(participant_id_changes[0]["changed_at"]).to be_present
          expect(participant_id_changes[0]["changed_at"]).to eq(teacher_id_change_1.created_at.utc.rfc3339)

          expect(participant_id_changes[1]["from_participant_id"]).to be_present
          expect(participant_id_changes[1]["from_participant_id"]).to eq(teacher_id_change_2.api_from_teacher_id)
          expect(participant_id_changes[1]["to_participant_id"]).to be_present
          expect(participant_id_changes[1]["to_participant_id"]).to eq(teacher_id_change_2.api_to_teacher_id)
          expect(participant_id_changes[1]["changed_at"]).to be_present
          expect(participant_id_changes[1]["changed_at"]).to eq(teacher_id_change_2.created_at.utc.rfc3339)
        end
      end
    end

    describe "ecf_enrolments" do
      subject(:ecf_enrolments) { response["attributes"]["ecf_enrolments"] }

      let(:mock_teacher_status) { instance_double(API::TrainingPeriods::TeacherStatus, status: "active") }

      before do
        if defined?(ect_training_period)
          allow(API::TrainingPeriods::TeacherStatus).to receive(:new).with(latest_training_period: ect_training_period, teacher:).and_return(mock_teacher_status)
        end

        if defined?(mentor_training_period)
          allow(API::TrainingPeriods::TeacherStatus).to receive(:new).with(latest_training_period: mentor_training_period, teacher:).and_return(mock_teacher_status)
        end
      end

      it { is_expected.to be_empty }

      context "when there are ECT/mentor training periods for the lead provider" do
        let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, lead_provider:) }
        let(:school_partnership) do
          FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
        end
        let(:school) { school_partnership.school }

        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: 2.months.ago, finished_on: nil) }
        let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period:, school_partnership:) }

        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:, started_on: 2.months.ago, finished_on: nil) }
        let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period:, school_partnership:) }

        let(:other_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 2.months.ago, finished_on: nil) }
        let!(:other_mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: other_mentor_at_school_period, school_partnership:) }

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

          it "serializes correctly" do
            expect(ect_enrolment["training_record_id"]).to be_present
            expect(ect_enrolment["training_record_id"]).to eq(teacher.api_ect_training_record_id)

            expect(ect_enrolment["email"]).to be_present
            expect(ect_enrolment["email"]).to eq(ect_at_school_period.email)

            expect(ect_enrolment["mentor_id"]).to be_present
            expect(ect_enrolment["mentor_id"]).to eq(latest_mentorship_period.mentor.teacher.api_id)

            expect(ect_enrolment["school_urn"]).to be_present
            expect(ect_enrolment["school_urn"]).to eq(ect_training_period.school_partnership.school.urn.to_s)

            expect(ect_enrolment["participant_type"]).to eq("ect")

            expect(ect_enrolment["cohort"]).to be_present
            expect(ect_enrolment["cohort"]).to eq(ect_training_period.school_partnership.contract_period.year.to_s)

            expect(ect_enrolment["training_status"]).to eq("active")

            expect(ect_enrolment["withdrawal"]).to be_nil

            expect(ect_enrolment["deferral"]).to be_nil

            expect(ect_enrolment["participant_status"]).to eq(mock_teacher_status.status)

            expect(ect_enrolment["pupil_premium_uplift"]).to be_present
            expect(ect_enrolment["pupil_premium_uplift"]).to eq(teacher.ect_pupil_premium_uplift)

            expect(ect_enrolment["sparsity_uplift"]).to be_present
            expect(ect_enrolment["sparsity_uplift"]).to eq(teacher.ect_sparsity_uplift)

            expect(ect_enrolment["schedule_identifier"]).to eq("ecf-standard-september")

            expect(ect_enrolment["delivery_partner_id"]).to be_present
            expect(ect_enrolment["delivery_partner_id"]).to eq(ect_training_period.school_partnership.delivery_partner.api_id)

            expect(ect_enrolment["created_at"]).to eq(teacher.earliest_ect_at_school_period.created_at.utc.rfc3339)

            expect(ect_enrolment["induction_end_date"]).to be_nil

            expect(ect_enrolment["overall_induction_start_date"]).to be_nil

            expect(ect_enrolment["mentor_funding_end_date"]).to be_nil

            expect(ect_enrolment["mentor_became_ineligible_for_funding_reason"]).to be_nil

            expect(ect_enrolment["cohort_changed_after_payments_frozen"]).to eq(teacher.ect_payments_frozen_year.present?)
          end

          context "when there is no latest mentor training period" do
            let(:latest_mentorship_period) { nil }

            it "serializes `mentor_id` as nil" do
              expect(ect_enrolment["mentor_id"]).to be_nil
            end
          end

          context "when `eligible_for_funding` is true" do
            let(:teacher) { FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: Time.zone.now) }

            it "serializes `eligible_for_funding`" do
              expect(ect_enrolment["eligible_for_funding"]).to be(true)
            end
          end

          context "when `eligible_for_funding` is false" do
            let(:teacher) { FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: nil) }

            it "serializes `eligible_for_funding`" do
              expect(ect_enrolment["eligible_for_funding"]).to be(false)
            end
          end

          describe "`induction_end_date`" do
            context "when a finished induction period is present" do
              let!(:finished_induction_period) { FactoryBot.create(:induction_period, :pass, teacher:) }

              it "serializes `induction_end_date` from finished induction period" do
                expect(ect_enrolment["induction_end_date"]).to eq(finished_induction_period.finished_on.to_fs(:api))
              end
            end

            context "when a finished induction period is not present" do
              before { teacher.update!(trs_induction_completed_date: Date.new(2024, 9, 18)) }

              it "serializes `induction_end_date` from TRS induction completed date" do
                expect(ect_enrolment["induction_end_date"]).to eq(teacher.trs_induction_completed_date.to_fs(:api))
              end
            end
          end

          describe "`overall_induction_start_date`" do
            context "when a started induction period is present" do
              let!(:started_induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher:) }

              it "serializes `overall_induction_start_date` from started induction period" do
                expect(ect_enrolment["overall_induction_start_date"]).to eq(started_induction_period.started_on.to_fs(:api))
              end
            end

            context "when a started induction period is not present" do
              before { teacher.update!(trs_induction_start_date: Date.new(2024, 9, 18)) }

              it "serializes `overall_induction_start_date` from TRS induction start date" do
                expect(ect_enrolment["overall_induction_start_date"]).to eq(teacher.trs_induction_start_date.to_fs(:api))
              end
            end
          end

          context "when `training_status` is withdrawn" do
            before { ect_training_period.update!(withdrawn_at: 3.days.ago, withdrawal_reason: :moved_school) }

            it "serializes the withdrawal" do
              expect(ect_enrolment["training_status"]).to eq("withdrawn")
              expect(ect_enrolment["withdrawal"]).to eq({ "date" => ect_training_period.withdrawn_at.utc.rfc3339, "reason" => "moved-school" })
            end
          end

          context "when `training_status` is deferred" do
            before { ect_training_period.update!(deferred_at: 3.days.ago, deferral_reason: :bereavement) }

            it "serializes the deferral" do
              expect(ect_enrolment["training_status"]).to eq("deferred")
              expect(ect_enrolment["deferral"]).to eq({ "date" => ect_training_period.deferred_at.utc.rfc3339, "reason" => "bereavement" })
            end
          end
        end

        describe "mentor enrolment" do
          subject(:mentor_enrolment) { response["attributes"]["ecf_enrolments"][1] }

          it "serializes correctly" do
            expect(mentor_enrolment["training_record_id"]).to be_present
            expect(mentor_enrolment["training_record_id"]).to eq(teacher.api_mentor_training_record_id)

            expect(mentor_enrolment["email"]).to be_present
            expect(mentor_enrolment["email"]).to eq(mentor_at_school_period.email)

            expect(mentor_enrolment["mentor_id"]).to be_nil

            expect(mentor_enrolment["school_urn"]).to be_present
            expect(mentor_enrolment["school_urn"]).to eq(mentor_training_period.school_partnership.school.urn.to_s)

            expect(mentor_enrolment["participant_type"]).to eq("mentor")

            expect(mentor_enrolment["cohort"]).to be_present
            expect(mentor_enrolment["cohort"]).to eq(mentor_training_period.school_partnership.contract_period.year.to_s)

            expect(mentor_enrolment["training_status"]).to eq("active")

            expect(mentor_enrolment["withdrawal"]).to be_nil

            expect(mentor_enrolment["deferral"]).to be_nil

            expect(mentor_enrolment["participant_status"]).to eq(mock_teacher_status.status)

            expect(mentor_enrolment["pupil_premium_uplift"]).to be(false)

            expect(mentor_enrolment["sparsity_uplift"]).to be(false)

            expect(mentor_enrolment["schedule_identifier"]).to eq("ecf-standard-september")

            expect(mentor_enrolment["delivery_partner_id"]).to be_present
            expect(mentor_enrolment["delivery_partner_id"]).to eq(mentor_training_period.school_partnership.delivery_partner.api_id)

            expect(mentor_enrolment["created_at"]).to eq(teacher.earliest_mentor_at_school_period.created_at.utc.rfc3339)

            expect(mentor_enrolment["induction_end_date"]).to be_nil

            expect(mentor_enrolment["overall_induction_start_date"]).to be_nil

            expect(mentor_enrolment["mentor_funding_end_date"]).to eq(teacher.mentor_became_ineligible_for_funding_on.to_fs(:api))

            expect(mentor_enrolment["mentor_ineligible_for_funding_reason"]).to be_present
            expect(mentor_enrolment["mentor_ineligible_for_funding_reason"]).to eq(teacher.mentor_became_ineligible_for_funding_reason)

            expect(mentor_enrolment["cohort_changed_after_payments_frozen"]).to eq(teacher.mentor_payments_frozen_year.present?)
          end

          context "when `eligible_for_funding` is true" do
            let(:teacher) { FactoryBot.create(:teacher, mentor_first_became_eligible_for_training_at: Time.zone.now) }

            it "serializes `eligible_for_funding`" do
              expect(mentor_enrolment["eligible_for_funding"]).to be(true)
            end
          end

          context "when `eligible_for_funding` is false" do
            let(:teacher) { FactoryBot.create(:teacher, mentor_first_became_eligible_for_training_at: nil) }

            it "serializes `eligible_for_funding`" do
              expect(mentor_enrolment["eligible_for_funding"]).to be(false)
            end
          end

          context "when there is no `mentor_funding_end_date`" do
            before { teacher.update!(mentor_became_ineligible_for_funding_on: nil, mentor_became_ineligible_for_funding_reason: nil) }

            it "serializes `mentor_funding_end_date` as nil" do
              expect(mentor_enrolment["mentor_funding_end_date"]).to be_nil
            end
          end

          context "when `training_status` is withdrawn" do
            before { mentor_training_period.update!(withdrawn_at: 3.days.ago, withdrawal_reason: :moved_school) }

            it "serializes the withdrawal" do
              expect(mentor_enrolment["training_status"]).to eq("withdrawn")
              expect(mentor_enrolment["withdrawal"]).to eq({ "date" => mentor_training_period.withdrawn_at.utc.rfc3339, "reason" => "moved-school" })
            end
          end

          context "when `training_status` is deferred" do
            before { mentor_training_period.update!(deferred_at: 3.days.ago, deferral_reason: :bereavement) }

            it "serializes the deferral" do
              expect(mentor_enrolment["training_status"]).to eq("deferred")
              expect(mentor_enrolment["deferral"]).to eq({ "date" => mentor_training_period.deferred_at.utc.rfc3339, "reason" => "bereavement" })
            end
          end
        end
      end
    end
  end
end
