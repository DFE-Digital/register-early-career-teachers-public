describe ECF2TeacherHistory do
  subject { ECF2TeacherHistory.new(teacher_row:, **other_arguments) }

  let(:trn) { "2345678" }
  let(:trs_first_name) { "Colin" }
  let(:trs_last_name) { "Jeavons" }
  let(:corrected_name) { "Colin Abel Jeavons" }
  let(:teacher_row) { ECF2TeacherHistory::TeacherRow.new(trn:, trs_first_name:, trs_last_name:, corrected_name:) }

  let!(:school_a) { FactoryBot.create(:school, urn: 111_111) }
  let!(:school_b) { FactoryBot.create(:school, urn: 222_222) }
  let(:school_a_data) { ECF2TeacherHistory::SchoolData.new(urn: 111_111, name: "School A") }
  let(:school_b_data) { ECF2TeacherHistory::SchoolData.new(urn: 222_222, name: "School B") }
  let(:mentor_data) { ECF2TeacherHistory::MentorData.new(trn: "1234567", urn: "123456", started_on: 1.week.ago, finished_on: 1.day.ago) }
  let(:created_at) { 1.month.ago.round }

  let(:mentorship_period_rows) do
    [
      ECF2TeacherHistory::MentorshipPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        ecf_start_induction_record_id: SecureRandom.uuid,
        ecf_end_induction_record_id: SecureRandom.uuid,
        mentor_data:
      )
    ]
  end

  let(:training_period_rows) do
    [
      ECF2TeacherHistory::TrainingPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        created_at:,
        training_programme: :provider_led
      ),
    ]
  end

  let(:ect_at_school_period_rows) do
    [
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        school: school_a_data,
        email: "a@example.org",
        mentorship_period_rows:,
        training_period_rows:
      )
    ]
  end

  let(:mentor_at_school_period_rows) do
    [
      ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        school: school_a_data,
        email: "a@example.org",
        training_period_rows:
      )
    ]
  end

  let(:other_arguments) { {} }

  describe "#initialize" do
    it "is initialized with a teacher row" do
      expect(subject.teacher_row.trn).to eql(trn)
      expect(subject.teacher_row.trs_first_name).to eql(trs_first_name)
      expect(subject.teacher_row.trs_last_name).to eql(trs_last_name)
      expect(subject.teacher_row.corrected_name).to eql(corrected_name)
    end

    context "when ect_at_school_period_rows are present" do
      let(:other_arguments) { { ect_at_school_period_rows: } }

      it "can be initialized with ect_at_school_period_rows" do
        expect(subject.ect_at_school_period_rows).to eql(ect_at_school_period_rows)
      end
    end

    context "when mentor_at_school_period_rows are present" do
      let(:other_arguments) { { mentor_at_school_period_rows: } }

      it "can be initialized with mentor_at_school_period_rows" do
        expect(subject.mentor_at_school_period_rows).to eql(mentor_at_school_period_rows)
      end
    end
  end

  describe "#save_all_ect_data!" do
    let(:contract_period) { FactoryBot.create(:contract_period) }

    it { is_expected.to respond_to(:save_all_ect_data!) }

    describe "saving a teacher" do
      let(:api_id) { SecureRandom.uuid }
      let(:api_ect_training_record_id) { SecureRandom.uuid }
      let(:api_mentor_training_record_id) { SecureRandom.uuid }
      let(:ect_pupil_premium_uplift) { true }
      let(:ect_sparsity_uplift) { true }
      let(:ect_first_became_eligible_for_training_at) { 3.years.ago.round(2) }
      let(:ect_payments_frozen_year) { contract_period.year }

      let(:teacher_row) do
        ECF2TeacherHistory::TeacherRow.new(
          trn:,
          trs_first_name:,
          trs_last_name:,
          corrected_name:,

          api_id:,
          api_ect_training_record_id:,
          api_mentor_training_record_id:,

          ect_pupil_premium_uplift:,
          ect_sparsity_uplift:,
          ect_first_became_eligible_for_training_at:,
          ect_payments_frozen_year:
        )
      end

      it "saves a row with the right values" do
        teacher = subject.save_all_ect_data!

        expect(teacher).to be_persisted

        aggregate_failures do
          expect(teacher.trn).to eql(trn)
          expect(teacher.trs_first_name).to eql(trs_first_name)
          expect(teacher.trs_last_name).to eql(trs_last_name)
          expect(teacher.corrected_name).to eql(corrected_name)

          expect(teacher.api_id).to eql(api_id)
          expect(teacher.api_ect_training_record_id).to eql(api_ect_training_record_id)
          expect(teacher.api_mentor_training_record_id).to eql(api_mentor_training_record_id)

          expect(teacher.ect_pupil_premium_uplift).to eql(ect_pupil_premium_uplift)
          expect(teacher.ect_sparsity_uplift).to eql(ect_sparsity_uplift)
          expect(teacher.ect_first_became_eligible_for_training_at).to eql(ect_first_became_eligible_for_training_at)
          expect(teacher.ect_payments_frozen_year).to eql(ect_payments_frozen_year)
        end
      end

      context "when the teacher record already exists" do
        pending "it updates the existing teacher record"
      end

      context "when the teacher has ECT at school periods" do
        let(:other_arguments) { { ect_at_school_period_rows: } }
        let(:teacher) { subject.save_all_ect_data! }

        let(:appropriate_body_a) { FactoryBot.create(:appropriate_body) }
        let(:appropriate_body_b) { FactoryBot.create(:appropriate_body) }
        let(:appropriate_body_a_data) do
          ECF2TeacherHistory::AppropriateBodyData.new(
            id: appropriate_body_a.id,
            name: appropriate_body_a.name
          )
        end
        let(:appropriate_body_b_data) do
          ECF2TeacherHistory::AppropriateBodyData.new(
            id: appropriate_body_b.id,
            name: appropriate_body_b.name
          )
        end

        context "when training periods are present" do
          let(:contract_period) { FactoryBot.create(:contract_period) }

          let(:lead_provider) { FactoryBot.create(:lead_provider) }
          let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
          let(:schedule_info) { Types::ScheduleInfo.new(schedule_id: schedule.id, identifier: schedule.identifier, name: schedule.identifier, cohort_year: schedule.contract_period_year) }

          let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
          let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }

          let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school_a, lead_provider_delivery_partnership:) }

          let(:first_training_period_row) do
            ECF2TeacherHistory::TrainingPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              created_at:,
              training_programme: :provider_led,
              lead_provider_info:,
              delivery_partner_info:,
              contract_period:,
              schedule_info:
              # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
              # deferred_at: 2.months.ago.round(2),
              # deferral_reason: "career_break",
              # withdrawn_at: 1.month.ago.round(2),
              # withdrawal_reason: "switched_to_school_led"
            )
          end

          let(:first_ect_at_school_period_row) do
            ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              school: school_a_data,
              email: "a@example.org",
              appropriate_body: appropriate_body_a_data,
              training_period_rows: [first_training_period_row],
              mentorship_period_rows: []
            )
          end

          let(:second_training_period_row) do
            ECF2TeacherHistory::TrainingPeriodRow.new(
              started_on: 1.month.ago.to_date,
              finished_on: 1.week.ago.to_date,
              created_at:,
              training_programme: :school_led
            )
          end

          let(:second_ect_at_school_period_row) do
            ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
              started_on: 1.month.ago.to_date,
              finished_on: 1.week.ago.to_date,
              school: school_b_data,
              email: "b@example.org",
              appropriate_body: appropriate_body_b_data,
              training_period_rows: [second_training_period_row],
              mentorship_period_rows: []
            )
          end

          let(:ect_at_school_period_rows) do
            [first_ect_at_school_period_row, second_ect_at_school_period_row]
          end

          it "saves the right number of ECT at school periods" do
            expect(teacher.ect_at_school_periods.count).to be(2)
          end

          it "saves the right number of training periods" do
            expect(teacher.ect_at_school_periods.first.training_periods.count).to be(1)
            expect(teacher.ect_at_school_periods.second.training_periods.count).to be(1)
          end

          it "saves provider led training periods with the right data" do
            aggregate_failures do
              teacher.ect_at_school_periods.first.tap do |p1|
                expect(p1.started_on).to eql(1.year.ago.to_date)
                expect(p1.finished_on).to eql(1.month.ago.to_date)
                expect(p1.school.urn).to eql(school_a_data.urn)
                expect(p1.email).to eql("a@example.org")
                # expect(p1.school_reported_appropriate_body.id).to eql(appropriate_body_a_data.id)

                p1.training_periods.first!.tap do |p1_tp|
                  expect(p1_tp.started_on).to eql(1.year.ago.to_date)
                  expect(p1_tp.finished_on).to eql(1.month.ago.to_date)
                  expect(p1_tp.training_programme).to eql("provider_led")
                  expect(p1_tp.contract_period).to eql(contract_period)
                  expect(p1_tp.lead_provider_delivery_partnership).to eql(lead_provider_delivery_partnership)
                  expect(p1_tp.active_lead_provider).to eql(active_lead_provider)
                  expect(p1_tp.lead_provider).to eql(lead_provider)
                  expect(p1_tp.contract_period).to eql(contract_period)
                  expect(p1_tp.schedule).to eql(schedule)
                  expect(p1_tp.created_at).to eql(created_at)
                  # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
                  # expect(p1_tp.withdrawn_at).to eql(1.month.ago.round(2))
                  # expect(p1_tp.withdrawal_reason).to eql("switched_to_school_led")
                  # expect(p1_tp.deferred_at).to eql(2.months.ago.round(2))
                  # expect(p1_tp.deferral_reason).to eql("career_break")
                end
              end
            end
          end

          it "saves school led training periods with the right data" do
            aggregate_failures do
              teacher.ect_at_school_periods.second.tap do |p2|
                expect(p2.started_on).to eql(1.month.ago.to_date)
                expect(p2.finished_on).to eql(1.week.ago.to_date)
                expect(p2.school.urn).to eql(school_b_data.urn)
                expect(p2.email).to eql("b@example.org")
                # expect(p2.school_reported_appropriate_body.id).to eql(appropriate_body_b_data.id)

                p2.training_periods.first!.tap do |p2_tp|
                  expect(p2_tp.started_on).to eql(1.month.ago.to_date)
                  expect(p2_tp.finished_on).to eql(1.week.ago.to_date)
                  expect(p2_tp.created_at).to eql(created_at)
                  expect(p2_tp.training_programme).to eql("school_led")
                  expect(p2_tp.schedule).to be_nil
                end
              end
            end
          end
        end

        context "when mentorship periods are present" do
          let(:existing_mentor_at_school_period) do
            FactoryBot.create(
              :mentor_at_school_period,
              school: school_a,
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date
            )
          end

          let(:mentor_data) do
            ECF2TeacherHistory::MentorData.new(
              trn: existing_mentor_at_school_period.teacher.trn,
              urn: existing_mentor_at_school_period.school.urn,
              started_on: existing_mentor_at_school_period.started_on,
              finished_on: existing_mentor_at_school_period.finished_on
            )
          end

          let(:mentorship_period_row) do
            ECF2TeacherHistory::MentorshipPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              ecf_start_induction_record_id: SecureRandom.uuid,
              ecf_end_induction_record_id: SecureRandom.uuid,
              mentor_data:
            )
          end

          let(:ect_at_school_period_row) do
            ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              appropriate_body: appropriate_body_a_data,
              school: school_a_data,
              email: "a@example.org",
              mentorship_period_rows: [mentorship_period_row],
              training_period_rows: []
            )
          end

          let(:ect_at_school_period_rows) { [ect_at_school_period_row] }

          it "saves the right number of ECT at school periods" do
            expect(teacher.ect_at_school_periods.count).to be(1)
          end

          it "saves the right number of mentorship periods" do
            expect(teacher.ect_at_school_periods.first.mentorship_periods.count).to be(1)
          end

          it "saves mentorship periods with the right data" do
            aggregate_failures do
              teacher.ect_at_school_periods.first.tap do |p1|
                expect(p1.started_on).to eql(1.year.ago.to_date)
                expect(p1.finished_on).to eql(1.month.ago.to_date)
                expect(p1.school.urn).to eql(school_a_data.urn)
                expect(p1.email).to eql("a@example.org")
                # expect(p1.school_reported_appropriate_body.id).to eql(appropriate_body_a_data.id)

                p1.mentorship_periods.first!.tap do |p1_mp|
                  expect(p1_mp.started_on).to eql(1.year.ago.to_date)
                  expect(p1_mp.finished_on).to eql(1.month.ago.to_date)
                  expect(p1_mp.mentor).to eql(existing_mentor_at_school_period)
                  expect(p1_mp.ecf_start_induction_record_id).to eql(mentorship_period_row.ecf_start_induction_record_id)
                  expect(p1_mp.ecf_end_induction_record_id).to eql(mentorship_period_row.ecf_end_induction_record_id)
                end
              end
            end
          end
        end
      end
    end
  end

  describe "#save_all_mentor_data!" do
    let(:contract_period) { FactoryBot.create(:contract_period) }

    it { is_expected.to respond_to(:save_all_mentor_data!) }

    describe "saving a teacher" do
      let(:api_id) { SecureRandom.uuid }
      let(:api_ect_training_record_id) { SecureRandom.uuid }
      let(:api_mentor_training_record_id) { SecureRandom.uuid }
      let(:mentor_became_ineligible_for_funding_on) { 2.years.ago.to_date }
      let(:mentor_became_ineligible_for_funding_reason) { "completed_declaration_received" }
      let(:mentor_first_became_eligible_for_training_at) { 2.years.ago.round(2) }
      let(:mentor_payments_frozen_year) { contract_period.year }

      let(:teacher_row) do
        ECF2TeacherHistory::TeacherRow.new(
          trn:,
          trs_first_name:,
          trs_last_name:,
          corrected_name:,

          api_id:,
          api_ect_training_record_id:,
          api_mentor_training_record_id:,

          mentor_became_ineligible_for_funding_on:,
          mentor_became_ineligible_for_funding_reason:,
          mentor_first_became_eligible_for_training_at:,
          mentor_payments_frozen_year:
        )
      end

      it "saves a row with the right values" do
        teacher = subject.save_all_mentor_data!

        expect(teacher).to be_persisted

        aggregate_failures do
          expect(teacher.trn).to eql(trn)
          expect(teacher.trs_first_name).to eql(trs_first_name)
          expect(teacher.trs_last_name).to eql(trs_last_name)
          expect(teacher.corrected_name).to eql(corrected_name)

          expect(teacher.api_id).to eql(api_id)
          expect(teacher.api_ect_training_record_id).to eql(api_ect_training_record_id)
          expect(teacher.api_mentor_training_record_id).to eql(api_mentor_training_record_id)

          expect(teacher.ect_pupil_premium_uplift).to be(false)
          expect(teacher.ect_sparsity_uplift).to be(false)

          expect(teacher.mentor_became_ineligible_for_funding_on).to eql(mentor_became_ineligible_for_funding_on)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eql(mentor_became_ineligible_for_funding_reason)
          expect(teacher.mentor_first_became_eligible_for_training_at).to eql(mentor_first_became_eligible_for_training_at)
          expect(teacher.mentor_payments_frozen_year).to eql(mentor_payments_frozen_year)
        end
      end

      context "when the teacher record already exists" do
        pending "it updates the existing teacher record"
      end

      context "when the teacher has mentor at school periods" do
        let(:other_arguments) { { mentor_at_school_period_rows: } }
        let(:teacher) { subject.save_all_mentor_data! }

        let(:appropriate_body_a) { FactoryBot.create(:appropriate_body) }
        let(:appropriate_body_b) { FactoryBot.create(:appropriate_body) }
        let(:appropriate_body_a_data) do
          ECF2TeacherHistory::AppropriateBodyData.new(
            id: appropriate_body_a.id,
            name: appropriate_body_a.name
          )
        end
        let(:appropriate_body_b_data) do
          ECF2TeacherHistory::AppropriateBodyData.new(
            id: appropriate_body_b.id,
            name: appropriate_body_b.name
          )
        end

        context "when training periods are present" do
          let(:contract_period) { FactoryBot.create(:contract_period) }
          let(:lead_provider) { FactoryBot.create(:lead_provider) }
          let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
          let(:schedule_info) { Types::ScheduleInfo.new(schedule_id: schedule.id, identifier: schedule.identifier, name: schedule.identifier, cohort_year: schedule.contract_period_year) }

          let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
          let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }

          let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school_a, lead_provider_delivery_partnership:) }

          let(:first_training_period_row) do
            ECF2TeacherHistory::TrainingPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              created_at:,
              training_programme: :provider_led,
              lead_provider_info:,
              delivery_partner_info:,
              contract_period:,
              schedule_info:
              # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
              # deferred_at: 2.months.ago.round(2),
              # deferral_reason: "career_break",
              # withdrawn_at: 1.month.ago.round(2),
              # withdrawal_reason: "switched_to_school_led"
            )
          end

          let(:first_mentor_at_school_period_row) do
            ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              school: school_a_data,
              email: "a@example.org",
              training_period_rows: [first_training_period_row]
            )
          end

          let(:mentor_at_school_period_rows) do
            [first_mentor_at_school_period_row]
          end

          it "saves the right number of ECT at school periods" do
            expect(teacher.mentor_at_school_periods.count).to be(1)
          end

          it "saves the right number of training periods" do
            expect(teacher.mentor_at_school_periods.first.training_periods.count).to be(1)
          end

          it "saves provider led training periods with the right data" do
            aggregate_failures do
              teacher.mentor_at_school_periods.first.tap do |p1|
                expect(p1.started_on).to eql(1.year.ago.to_date)
                expect(p1.finished_on).to eql(1.month.ago.to_date)
                expect(p1.school.urn).to eql(school_a_data.urn)
                expect(p1.email).to eql("a@example.org")

                p1.training_periods.first!.tap do |p1_tp|
                  expect(p1_tp.started_on).to eql(1.year.ago.to_date)
                  expect(p1_tp.finished_on).to eql(1.month.ago.to_date)
                  expect(p1_tp.training_programme).to eql("provider_led")
                  expect(p1_tp.contract_period).to eql(contract_period)
                  expect(p1_tp.lead_provider_delivery_partnership).to eql(lead_provider_delivery_partnership)
                  expect(p1_tp.active_lead_provider).to eql(active_lead_provider)
                  expect(p1_tp.lead_provider).to eql(lead_provider)
                  expect(p1_tp.contract_period).to eql(contract_period)
                  # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
                  # expect(p1_tp.withdrawn_at).to eql(1.month.ago.round(2))
                  # expect(p1_tp.withdrawal_reason).to eql("switched_to_school_led")
                  # expect(p1_tp.deferred_at).to eql(2.months.ago.round(2))
                  # expect(p1_tp.deferral_reason).to eql("career_break")
                end
              end
            end
          end
        end
      end
    end
  end
end
