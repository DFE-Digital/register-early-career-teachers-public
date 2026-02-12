describe ECF2TeacherHistory do
  subject { ECF2TeacherHistory.new(teacher: teacher_data, **other_arguments) }

  let(:trn) { "2345678" }
  let(:trs_first_name) { "Colin" }
  let(:trs_last_name) { "Jeavons" }
  let(:corrected_name) { "Colin Abel Jeavons" }
  let(:teacher_data) { ECF2TeacherHistory::Teacher.new(trn:, trs_first_name:, trs_last_name:, corrected_name:) }

  let!(:school_a) { FactoryBot.create(:school, urn: 111_111) }
  let!(:school_b) { FactoryBot.create(:school, urn: 222_222) }
  let(:school_a_data) { Types::SchoolData.new(urn: 111_111, name: "School A") }
  let(:school_b_data) { Types::SchoolData.new(urn: 222_222, name: "School B") }
  let(:created_at) { 1.month.ago.round }

  let(:mentorship_periods) do
    [
      ECF2TeacherHistory::MentorshipPeriod.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        ecf_start_induction_record_id: SecureRandom.uuid,
        ecf_end_induction_record_id: SecureRandom.uuid,
        mentor_at_school_period_id: SecureRandom.uuid,
        api_ect_training_record_id: SecureRandom.uuid,
        api_mentor_training_record_id: SecureRandom.uuid
      )
    ]
  end

  let(:training_periods) do
    [
      ECF2TeacherHistory::TrainingPeriod.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        created_at:,
        training_programme: :provider_led
      ),
    ]
  end

  let(:ect_at_school_periods) do
    [
      ECF2TeacherHistory::ECTAtSchoolPeriod.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        school: school_a_data,
        email: "a@example.org",
        mentorship_periods:,
        training_periods:
      )
    ]
  end

  let(:mentor_at_school_periods) do
    [
      ECF2TeacherHistory::MentorAtSchoolPeriod.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        school: school_a_data,
        email: "a@example.org",
        training_periods:
      )
    ]
  end

  let(:other_arguments) { {} }

  describe "#initialize" do
    it "is initialized with a teacher" do
      aggregate_failures do
        expect(subject.teacher.trn).to eql(trn)
        expect(subject.teacher.trs_first_name).to eql(trs_first_name)
        expect(subject.teacher.trs_last_name).to eql(trs_last_name)
        expect(subject.teacher.corrected_name).to eql(corrected_name)
      end
    end

    context "when ect_at_school_periods are present" do
      let(:other_arguments) { { ect_at_school_periods: } }

      it "can be initialized with ect_at_school_periods" do
        expect(subject.ect_at_school_periods).to eql(ect_at_school_periods)
      end
    end

    context "when mentor_at_school_periods are present" do
      let(:other_arguments) { { mentor_at_school_periods: } }

      it "can be initialized with mentor_at_school_periods" do
        expect(subject.mentor_at_school_periods).to eql(mentor_at_school_periods)
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
      let(:migration_mode) { "latest_induction_records" }
      let(:ect_pupil_premium_uplift) { true }
      let(:ect_sparsity_uplift) { true }
      let(:ect_first_became_eligible_for_training_at) { 3.years.ago.round(2) }
      let(:ect_payments_frozen_year) { contract_period.year }

      let(:teacher_data) do
        ECF2TeacherHistory::Teacher.new(
          trn:,
          trs_first_name:,
          trs_last_name:,
          corrected_name:,

          api_id:,
          api_ect_training_record_id:,
          api_mentor_training_record_id:,

          migration_mode:,

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

          expect(teacher.migration_mode).to eql(migration_mode)
          expect(teacher.ect_pupil_premium_uplift).to eql(ect_pupil_premium_uplift)
          expect(teacher.ect_sparsity_uplift).to eql(ect_sparsity_uplift)
          expect(teacher.ect_first_became_eligible_for_training_at).to eql(ect_first_became_eligible_for_training_at)
          expect(teacher.ect_payments_frozen_year).to eql(ect_payments_frozen_year)
        end
      end

      context "when the teacher record already exists" do
        let!(:existing_teacher) do
          FactoryBot.create(
            :teacher,
            trn:,
            trs_first_name: "Old First Name",
            trs_last_name: "Old Last Name",
            corrected_name: nil
          )
        end

        it "does not create a new teacher record" do
          expect { subject.save_all_ect_data! }.not_to change(Teacher, :count)
        end

        it "updates the existing teacher's corrected name" do
          teacher = subject.save_all_ect_data!

          aggregate_failures do
            expect(teacher.id).to eql(existing_teacher.id)
            expect(teacher.corrected_name).to eql(corrected_name)
          end
        end

        it "does not overwrite the trs_first_name and trs_last_name fields" do
          teacher = subject.save_all_ect_data!

          aggregate_failures do
            expect(teacher.trs_first_name).to eql("Old First Name")
            expect(teacher.trs_last_name).to eql("Old Last Name")
          end
        end

        it "updates ECT-specific attributes" do
          teacher = subject.save_all_ect_data!

          aggregate_failures do
            expect(teacher.api_ect_training_record_id).to eql(api_ect_training_record_id)
            expect(teacher.migration_mode).to eql(migration_mode)
            expect(teacher.ect_pupil_premium_uplift).to eql(ect_pupil_premium_uplift)
            expect(teacher.ect_sparsity_uplift).to eql(ect_sparsity_uplift)
          end
        end
      end

      context "when the teacher has ECT at school periods" do
        let(:other_arguments) { { ect_at_school_periods: } }
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
          let(:contract_period) { FactoryBot.create(:contract_period, year: 2021) }

          let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
          let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
          let(:schedule_info) { Types::ScheduleInfo.new(schedule_id: schedule.id, identifier: schedule.identifier, name: schedule.identifier, cohort_year: schedule.contract_period_year) }

          let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
          let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }

          let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school_a, lead_provider_delivery_partnership:) }

          let(:first_training_period) do
            ECF2TeacherHistory::TrainingPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              created_at:,
              training_programme: :provider_led,
              lead_provider_info:,
              delivery_partner_info:,
              contract_period_year: contract_period.year,
              schedule_info:,
              school: school_a_data,
              combination: ::ECF2TeacherHistory::Combination.new(
                induction_record_id: SecureRandom.uuid,
                school_urn: school_a_data.urn,
                cohort_year: contract_period.year,
                lead_provider_name: lead_provider_info.name
              )
              # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
              # deferred_at: 2.months.ago.round(2),
              # deferral_reason: "career_break",
              # withdrawn_at: 1.month.ago.round(2),
              # withdrawal_reason: "switched_to_school_led"
            )
          end

          let(:first_ect_at_school_period) do
            ECF2TeacherHistory::ECTAtSchoolPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              school: school_a_data,
              email: "a@example.org",
              appropriate_body: appropriate_body_a_data,
              training_periods: [first_training_period],
              mentorship_periods: []
            )
          end

          let(:second_training_period) do
            ECF2TeacherHistory::TrainingPeriod.new(
              started_on: 1.month.ago.to_date,
              finished_on: 1.week.ago.to_date,
              created_at:,
              school: school_b_data,
              training_programme: :school_led,
              combination: ::ECF2TeacherHistory::Combination.new(
                induction_record_id: SecureRandom.uuid,
                school_urn: school_b_data.urn,
                lead_provider_name: nil
              )
            )
          end

          let(:second_ect_at_school_period) do
            ECF2TeacherHistory::ECTAtSchoolPeriod.new(
              started_on: 1.month.ago.to_date,
              finished_on: 1.week.ago.to_date,
              school: school_b_data,
              email: "b@example.org",
              appropriate_body: appropriate_body_b_data,
              training_periods: [second_training_period],
              mentorship_periods: []
            )
          end

          let(:ect_at_school_periods) do
            [first_ect_at_school_period, second_ect_at_school_period]
          end

          it "saves the right number of ECT at school periods" do
            expect(teacher.ect_at_school_periods.count).to be(2)
          end

          it "saves the right number of training periods" do
            aggregate_failures do
              expect(teacher.ect_at_school_periods.first.training_periods.count).to be(1)
              expect(teacher.ect_at_school_periods.second.training_periods.count).to be(1)
            end
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

          it "saves the expected DataMigrationTeacherCombination" do
            expected_combinations = teacher.ect_at_school_periods.flat_map(&:training_periods).map do |training_period|
              [training_period.school.urn,
               training_period.contract_period&.year,
               training_period.lead_provider&.name].join(": ")
            end
            data_migration_teacher_combination = DataMigrationTeacherCombination.first

            expect(DataMigrationTeacherCombination.count).to be(1)
            expect(data_migration_teacher_combination.ecf1_ect_profile_id).to eq(teacher.api_ect_training_record_id)
            expect(data_migration_teacher_combination.ecf1_ect_combinations.map { it[39..-2] }).to match_array(expected_combinations)
            expect(data_migration_teacher_combination.ecf2_ect_combinations.map { it[39..-2] }).to match_array(expected_combinations)
          end

          context "when an ect_at_school_period can't be persisted" do
            let(:failure_message) { "ECTAtSchoolPeriod cant' be created!" }

            before do
              allow(ECTAtSchoolPeriod).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, failure_message)
            end

            it "saves a DataMigrationFailedCombination entry per training_period" do
              teacher

              expect(DataMigrationFailedCombination.count).to be(2)

              combinations = ect_at_school_periods.flat_map(&:training_periods).map(&:combination)
              induction_record_ids = combinations.map(&:induction_record_id)
              failed_combinations = DataMigrationFailedCombination.all

              expect(failed_combinations.map(&:induction_record_id)).to match_array(induction_record_ids)
              expect(failed_combinations.map(&:failure_message)).to contain_exactly(failure_message, failure_message)
            end
          end

          context "when an training_period can't be persisted" do
            let(:failure_message) { "TrainingPeriod cant' be created!" }

            before do
              allow(TrainingPeriod).to receive(:create!).and_call_original
              allow(TrainingPeriod).to receive(:create!)
                                         .with(hash_including(started_on: 1.year.ago.to_date))
                                         .and_raise(ActiveRecord::ActiveRecordError, failure_message)
            end

            it "saves a DataMigrationFailedCombination entry" do
              teacher

              expect(DataMigrationFailedCombination.count).to be(1)

              failed_combination = DataMigrationFailedCombination.first

              expect(failed_combination.induction_record_id).to eq(first_training_period.combination.induction_record_id)
              expect(failed_combination.failure_message).to eq(failure_message)
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

          let(:mentorship_period) do
            ECF2TeacherHistory::MentorshipPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              ecf_start_induction_record_id: SecureRandom.uuid,
              ecf_end_induction_record_id: SecureRandom.uuid,
              mentor_at_school_period_id: existing_mentor_at_school_period.id,
              api_ect_training_record_id:,
              api_mentor_training_record_id: existing_mentor_at_school_period.teacher.api_mentor_training_record_id
            )
          end

          let(:ect_at_school_period) do
            ECF2TeacherHistory::ECTAtSchoolPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              appropriate_body: appropriate_body_a_data,
              school: school_a_data,
              email: "a@example.org",
              mentorship_periods: [mentorship_period],
              training_periods: []
            )
          end

          let(:ect_at_school_periods) { [ect_at_school_period] }

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
                  expect(p1_mp.ecf_start_induction_record_id).to eql(mentorship_period.ecf_start_induction_record_id)
                  expect(p1_mp.ecf_end_induction_record_id).to eql(mentorship_period.ecf_end_induction_record_id)
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
      let(:migration_mode) { "all_induction_records" }
      let(:mentor_became_ineligible_for_funding_on) { 2.years.ago.to_date }
      let(:mentor_became_ineligible_for_funding_reason) { "completed_declaration_received" }
      let(:mentor_first_became_eligible_for_training_at) { 2.years.ago.round(2) }
      let(:mentor_payments_frozen_year) { contract_period.year }

      let(:teacher_data) do
        ECF2TeacherHistory::Teacher.new(
          trn:,
          trs_first_name:,
          trs_last_name:,
          corrected_name:,

          api_id:,
          api_ect_training_record_id:,
          api_mentor_training_record_id:,

          migration_mode:,

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

          expect(teacher.migration_mode).to eql(migration_mode)
          expect(teacher.mentor_became_ineligible_for_funding_on).to eql(mentor_became_ineligible_for_funding_on)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eql(mentor_became_ineligible_for_funding_reason)
          expect(teacher.mentor_first_became_eligible_for_training_at).to eql(mentor_first_became_eligible_for_training_at)
          expect(teacher.mentor_payments_frozen_year).to eql(mentor_payments_frozen_year)
        end
      end

      context "when the teacher record already exists" do
        let!(:existing_teacher) do
          FactoryBot.create(
            :teacher,
            trn:,
            trs_first_name: "Old First Name",
            trs_last_name: "Old Last Name",
            corrected_name: nil
          )
        end

        it "does not create a new teacher record" do
          expect { subject.save_all_mentor_data! }.not_to change(Teacher, :count)
        end

        it "updates the existing teacher record" do
          teacher = subject.save_all_mentor_data!

          aggregate_failures do
            expect(teacher.id).to eql(existing_teacher.id)
            expect(teacher.corrected_name).to eql(corrected_name)
          end
        end

        it "does not overwrite the trs_first_name and trs_last_name fields" do
          teacher = subject.save_all_ect_data!

          aggregate_failures do
            expect(teacher.trs_first_name).to eql("Old First Name")
            expect(teacher.trs_last_name).to eql("Old Last Name")
          end
        end

        it "updates mentor-specific attributes" do
          teacher = subject.save_all_mentor_data!

          aggregate_failures do
            expect(teacher.api_mentor_training_record_id).to eql(api_mentor_training_record_id)
            expect(teacher.migration_mode).to eql(migration_mode)
            expect(teacher.mentor_became_ineligible_for_funding_on).to eql(mentor_became_ineligible_for_funding_on)
            expect(teacher.mentor_became_ineligible_for_funding_reason).to eql(mentor_became_ineligible_for_funding_reason)
          end
        end
      end

      context "when the teacher has mentor at school periods" do
        let(:other_arguments) { { mentor_at_school_periods: } }
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
          let(:contract_period) { FactoryBot.create(:contract_period, year: 2021) }
          let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
          let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
          let(:schedule_info) { Types::ScheduleInfo.new(schedule_id: schedule.id, identifier: schedule.identifier, name: schedule.identifier, cohort_year: schedule.contract_period_year) }

          let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
          let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }

          let!(:school_partnership) { FactoryBot.create(:school_partnership, school: school_a, lead_provider_delivery_partnership:) }

          let(:first_training_period) do
            ECF2TeacherHistory::TrainingPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              created_at:,
              training_programme: :provider_led,
              lead_provider_info:,
              delivery_partner_info:,
              contract_period_year: contract_period.year,
              schedule_info:,
              school: school_a_data,
              combination: ::ECF2TeacherHistory::Combination.new(
                induction_record_id: SecureRandom.uuid,
                school_urn: school_a_data.urn,
                cohort_year: contract_period.year,
                lead_provider_name: lead_provider_info.name
              )
              # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
              # deferred_at: 2.months.ago.round(2),
              # deferral_reason: "career_break",
              # withdrawn_at: 1.month.ago.round(2),
              # withdrawal_reason: "switched_to_school_led"
            )
          end

          let(:first_mentor_at_school_period) do
            ECF2TeacherHistory::MentorAtSchoolPeriod.new(
              started_on: 1.year.ago.to_date,
              finished_on: 1.month.ago.to_date,
              school: school_a_data,
              email: "a@example.org",
              training_periods: [first_training_period]
            )
          end

          let(:mentor_at_school_periods) do
            [first_mentor_at_school_period]
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

          it "saves the expected DataMigrationTeacherCombination" do
            combinations = teacher.mentor_at_school_periods.map(&:training_periods).flatten.map do |training_period|
              [training_period.school.urn,
               training_period.contract_period&.year,
               training_period.lead_provider&.name].join(": ")
            end
            data_migration_teacher_combination = DataMigrationTeacherCombination.first

            expect(DataMigrationTeacherCombination.count).to be(1)
            expect(data_migration_teacher_combination.ecf1_mentor_profile_id).to eq(teacher.api_mentor_training_record_id)
            expect(data_migration_teacher_combination.ecf1_mentor_combinations.map { it[39..-2] }).to match_array(combinations)
            expect(data_migration_teacher_combination.ecf2_mentor_combinations.map { it[39..-2] }).to match_array(combinations)
          end

          context "when a mentor_at_school_period can't be persisted" do
            let(:failure_message) { "MentorATSchoolPeriod cant' be created!" }

            before do
              allow(MentorAtSchoolPeriod).to receive(:create!).and_raise(ActiveRecord::ActiveRecordError, failure_message)
            end

            it "saves a DataMigrationFailedCombination entry per training_period" do
              teacher

              expect(DataMigrationFailedCombination.count).to be(1)

              combinations = mentor_at_school_periods.flat_map(&:training_periods).map(&:combination)
              induction_record_ids = combinations.map(&:induction_record_id)
              failed_combinations = DataMigrationFailedCombination.all

              expect(failed_combinations.map(&:induction_record_id)).to match_array(induction_record_ids)
              expect(failed_combinations.map(&:failure_message)).to contain_exactly(failure_message)
            end
          end

          context "when an training_period can't be persisted" do
            let(:failure_message) { "TrainingPeriod cant' be created!" }

            before do
              allow(TrainingPeriod).to receive(:create!).and_call_original
              allow(TrainingPeriod).to receive(:create!)
                                         .with(hash_including(started_on: 1.year.ago.to_date))
                                         .and_raise(ActiveRecord::ActiveRecordError, failure_message)
            end

            it "saves a DataMigrationFailedCombination entry" do
              teacher

              expect(DataMigrationFailedCombination.count).to be(1)

              failed_combination = DataMigrationFailedCombination.first

              expect(failed_combination.induction_record_id).to eq(first_training_period.combination.induction_record_id)
              expect(failed_combination.failure_message).to eq(failure_message)
            end
          end
        end
      end
    end
  end

  describe "failure recording" do
    let(:other_arguments) { { ect_at_school_periods: } }

    describe "when SchoolPartnership is not found" do
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: contract_period.year) }
      let!(:lead_provider_delivery_partnership) do
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      end
      let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
      let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :provider_led,
          lead_provider_info:,
          delivery_partner_info:,
          contract_period_year: contract_period.year,
          ecf_start_induction_record_id:,
          school: school_a_data
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: school_a_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records the failure with the correct model" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.model).to eq("training_period")
      end

      it "records a specific error message" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to start_with("No SchoolPartnership found for training period")
      end

      it "records the migration item reference" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.migration_item_id).to eq(ecf_start_induction_record_id)
        expect(failure.migration_item_type).to eq("Migration::InductionRecord")
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end

    describe "when School is not found" do
      let(:nonexistent_school_data) { Types::SchoolData.new(urn: 999_999, name: "Nonexistent School") }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :school_led,
          ecf_start_induction_record_id:
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: nonexistent_school_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records the failure with the correct model" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.model).to eq("ect_at_school_period")
      end

      it "records a specific error message about the school" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to include("Couldn't find GIAS::School")
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end

    describe "when LeadProvider is not found" do
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:nonexistent_lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: SecureRandom.uuid, name: "Nonexistent LP") }
      let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :provider_led,
          lead_provider_info: nonexistent_lead_provider_info,
          delivery_partner_info:,
          contract_period_year: contract_period.year,
          ecf_start_induction_record_id:,
          school: school_a
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: school_a_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records the failure with the correct model" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.model).to eq("training_period")
      end

      it "records a specific error message about LeadProvider" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to include("Couldn't find LeadProvider")
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end

    describe "when ActiveLeadProvider is not found" do
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      # No ActiveLeadProvider created for this lead_provider + contract_period combo
      let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
      let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :provider_led,
          lead_provider_info:,
          delivery_partner_info:,
          contract_period_year: contract_period.year,
          ecf_start_induction_record_id:,
          school: school_a
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: school_a_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records a specific error message about ActiveLeadProvider" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to include("No ActiveLeadProvider found")
        expect(failure.message).to include(lead_provider.id.to_s)
        expect(failure.message).to include(contract_period.year.to_s)
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end

    describe "when LeadProviderDeliveryPartnership is not found" do
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: contract_period.year) }
      # No LeadProviderDeliveryPartnership created for this active_lead_provider + delivery_partner combo
      let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
      let(:delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: delivery_partner.api_id, name: delivery_partner.name) }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :provider_led,
          lead_provider_info:,
          delivery_partner_info:,
          contract_period_year: contract_period.year,
          ecf_start_induction_record_id:,
          school: school_a
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: school_a_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records a specific error message about LeadProviderDeliveryPartnership" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to include("No LeadProviderDeliveryPartnership found")
        expect(failure.message).to include(active_lead_provider.id.to_s)
        expect(failure.message).to include(delivery_partner.id.to_s)
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end

    describe "when DeliveryPartner is not found" do
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: contract_period.year) }
      let(:lead_provider_info) { Types::LeadProviderInfo.new(ecf1_id: lead_provider.ecf_id, name: lead_provider.name) }
      let(:nonexistent_delivery_partner_info) { Types::DeliveryPartnerInfo.new(ecf1_id: SecureRandom.uuid, name: "Nonexistent DP") }
      let(:ecf_start_induction_record_id) { SecureRandom.uuid }

      let(:training_period) do
        ECF2TeacherHistory::TrainingPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          created_at: 1.month.ago,
          training_programme: :provider_led,
          lead_provider_info:,
          delivery_partner_info: nonexistent_delivery_partner_info,
          contract_period_year: contract_period.year,
          ecf_start_induction_record_id:,
          school: school_a
        )
      end

      let(:ect_at_school_period) do
        ECF2TeacherHistory::ECTAtSchoolPeriod.new(
          started_on: 1.month.ago.to_date,
          finished_on: 1.week.ago.to_date,
          school: school_a_data,
          email: "a@example.org",
          mentorship_periods: [],
          training_periods: [training_period]
        )
      end

      let(:ect_at_school_periods) { [ect_at_school_period] }

      it "creates a TeacherMigrationFailure record" do
        expect { subject.save_all_ect_data! }.to change(TeacherMigrationFailure, :count).by(1)
      end

      it "records the failure with the correct model" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.model).to eq("training_period")
      end

      it "records a specific error message about DeliveryPartner" do
        subject.save_all_ect_data!
        failure = TeacherMigrationFailure.last

        expect(failure.message).to include("Couldn't find DeliveryPartner")
      end

      it "sets success? to false" do
        subject.save_all_ect_data!

        expect(subject.success?).to be(false)
      end
    end
  end
end
