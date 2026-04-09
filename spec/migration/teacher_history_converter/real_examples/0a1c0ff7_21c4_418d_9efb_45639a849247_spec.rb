describe "Real data check for user 0a1c0ff7-21c4-418d-9efb-45639a849247 (ERO mentor on training_period 'keep' list)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "0a1c0ff7-21c4-418d-9efb-45639a849247",
      created_at: Time.zone.local(2021, 7, 27, 10, 34, 51),
      updated_at: Time.zone.local(2025, 9, 12, 16, 12, 28),
      mentor: {
        participant_profile_id: "fafff34a-b37b-4920-960e-e03c1b48b481",
        created_at: Time.zone.local(2021, 7, 27, 10, 34, 51),
        updated_at: Time.zone.local(2025, 9, 12, 16, 12, 28),
        mentor_completion_date: Date.new(2021, 4, 19),
        mentor_completion_reason: "completed_during_early_roll_out",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2022, 9, 30),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "48122b4d-85ff-4e30-98e6-c7c9741cfba2",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "80e0a108-d5f7-433f-8c56-27b436b4dea8",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2022, 9, 30),
            end_date: Date.new(2022, 9, 30),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "48122b4d-85ff-4e30-98e6-c7c9741cfba2",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "0c8bbb38-ffc8-49fc-a116-ee5e17295a55",
              identifier: "ecf-standard-april",
              name: "ECF Standard April",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2022, 9, 30),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "48122b4d-85ff-4e30-98e6-c7c9741cfba2",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "0c8bbb38-ffc8-49fc-a116-ee5e17295a55",
              identifier: "ecf-standard-april",
              name: "ECF Standard April",
              cohort_year: 2021
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 7, 27, 10, 34, 51)
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2022, 5, 10, 14, 38, 45)
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: [],
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 9, 30),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              email: "a.teacher@example.com",
              training_periods: [
                hash_including(
                  started_on: Date.new(2022, 9, 30),
                  finished_on: Date.new(2022, 10, 1),
                  training_programme: "provider_led",
                  lead_provider_info: {
                    ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                    name: "Teach First"
                  },
                  delivery_partner_info: {
                    ecf1_id: "48122b4d-85ff-4e30-98e6-c7c9741cfba2",
                    name: "Delivery partner 1"
                  },
                  contract_period_year: 2021,
                  withdrawal_reason: nil,
                  withdrawn_at: nil,
                  deferral_reason: nil,
                  deferred_at: nil
                )
              ]
            )
          ),
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: [],
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 9, 30),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              email: "a.teacher@example.com",
              training_periods: [
                # NOTE: training_period added despite being after mentor_completion_date because mentor
                #       has this combo (participant_profile_id, lead_provider_id and cohort) in the combo check
                #       list so we don't discard it.
                hash_including(
                  started_on: Date.new(2022, 9, 30),
                  finished_on: Date.new(2022, 10, 1),
                  training_programme: "provider_led",
                  lead_provider_info: {
                    ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                    name: "Teach First"
                  },
                  delivery_partner_info: {
                    ecf1_id: "48122b4d-85ff-4e30-98e6-c7c9741cfba2",
                    name: "Delivery partner 1"
                  },
                  contract_period_year: 2021,
                  withdrawal_reason: nil,
                  withdrawn_at: nil,
                  deferral_reason: nil,
                  deferred_at: nil
                )
              ]
            )
          ),
          api_mentor_training_record_id: "fafff34a-b37b-4920-960e-e03c1b48b481",
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
