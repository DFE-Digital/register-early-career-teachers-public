describe "Real data check for user 0b850ce7-3af0-469b-b416-7dfbe5d91b2c" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "0b850ce7-3af0-469b-b416-7dfbe5d91b2c",
      created_at: Time.zone.local(2022, 6, 30, 11, 28, 28),
      updated_at: Time.zone.local(2025, 6, 30, 9, 55, 41),
      ect: {
        participant_profile_id: "e9e731d4-26e3-4031-b042-144508266bc5",
        created_at: Time.zone.local(2022, 6, 30, 11, 28, 28),
        updated_at: Time.zone.local(2025, 6, 30, 9, 55, 40),
        induction_start_date: Date.new(2022, 9, 1),
        induction_completion_date: Date.new(2024, 7, 12),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 6, 30, 11, 28, 28),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2025, 2, 11, 12, 37, 28),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          }
        ],
        induction_records: [
          {
            induction_record_id: "9f4b0091-f4b7-45f7-9633-0db3f083f0b6",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2022, 12, 2),
            created_at: Time.zone.local(2022, 6, 30, 11, 28, 28),
            updated_at: Time.zone.local(2022, 12, 2, 9, 47, 30),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d64ccd70-ab69-4920-8b27-17a563ffc49b",
            appropriate_body: {},
            training_provider_info: {},
            schedule_info: {
              schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2022
            }
          },
          {
            induction_record_id: "1f85518b-44f2-42a7-9bd5-4e042ed26e49",
            start_date: Date.new(2022, 12, 2),
            end_date: Date.new(2023, 7, 20),
            created_at: Time.zone.local(2022, 12, 2, 9, 47, 30),
            updated_at: Time.zone.local(2023, 7, 20, 9, 52, 51),
            training_programme: "core_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d64ccd70-ab69-4920-8b27-17a563ffc49b",
            appropriate_body: {
              ecf1_id: "7db7fce4-9a0e-492e-b7f4-48939c4659c7",
              name: "Gloucestershire"
            },
            training_provider_info: {},
            schedule_info: {
              schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2022
            }
          },
          {
            induction_record_id: "889471e9-279d-425f-8497-ce61bf107e26",
            start_date: Date.new(2023, 7, 20),
            end_date: Date.new(2023, 9, 8),
            created_at: Time.zone.local(2023, 7, 20, 9, 52, 51),
            updated_at: Time.zone.local(2023, 9, 8, 11, 24, 16),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d64ccd70-ab69-4920-8b27-17a563ffc49b",
            appropriate_body: {
              ecf1_id: "7db7fce4-9a0e-492e-b7f4-48939c4659c7",
              name: "Gloucestershire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "3e7d76a1-6031-47f5-b44b-ab2afd86e408",
                name: "Delivery partner 1"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2022
            }
          },
          {
            induction_record_id: "25f05353-3eca-486a-a909-d27fc7e999f4",
            start_date: Date.new(2023, 9, 8),
            end_date: Date.new(2024, 7, 16),
            created_at: Time.zone.local(2023, 9, 8, 11, 24, 16),
            updated_at: Time.zone.local(2024, 7, 16, 5, 38, 40),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d64ccd70-ab69-4920-8b27-17a563ffc49b",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "3e7d76a1-6031-47f5-b44b-ab2afd86e408",
                name: "Delivery partner 1"
              },
              cohort_year: 2023
            },
            schedule_info: {
              schedule_id: "db3d8a81-94b6-46ff-95dd-55f0e9b964e3",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2023
            }
          },
          {
            induction_record_id: "880a2b24-2ba9-42f4-9e54-ac4d5db3172e",
            start_date: Date.new(2024, 7, 16),
            end_date: Date.new(2025, 2, 11),
            created_at: Time.zone.local(2024, 7, 16, 5, 38, 40),
            updated_at: Time.zone.local(2025, 2, 11, 12, 37, 28),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "3e7d76a1-6031-47f5-b44b-ab2afd86e408",
                name: "Delivery partner 1"
              },
              cohort_year: 2023
            },
            schedule_info: {
              schedule_id: "db3d8a81-94b6-46ff-95dd-55f0e9b964e3",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2023
            }
          },
          {
            induction_record_id: "36f3b2ec-bf39-4ef3-b6dd-877f1bce0a76",
            start_date: Date.new(2025, 2, 11),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 2, 11, 12, 37, 28),
            updated_at: Time.zone.local(2025, 2, 11, 12, 37, 28),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "completed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "3e7d76a1-6031-47f5-b44b-ab2afd86e408",
                name: "Delivery partner 1"
              },
              cohort_year: 2023
            },
            schedule_info: {
              schedule_id: "db3d8a81-94b6-46ff-95dd-55f0e9b964e3",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2023
            }
          }
        ],
        mentor_at_school_periods: []
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
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 12, 2),
              finished_on: Date.new(2023, 7, 19),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 12, 2),
                  finished_on: Date.new(2023, 7, 19),
                  training_programme: "school_led",
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 7, 20),
              finished_on: Date.new(2023, 9, 8),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 7, 20),
                  finished_on: Date.new(2023, 9, 8),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 7, 12),
              finished_on: Date.new(2024, 7, 13),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 12),
                  finished_on: Date.new(2024, 7, 13),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023
                )
              )
            )
          )
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
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 12, 2),
              finished_on: Date.new(2024, 7, 16),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 12, 2),
                  finished_on: Date.new(2023, 7, 19),
                  training_programme: "school_led",
                  contract_period_year: 2022
                ),
                hash_including(
                  started_on: Date.new(2023, 7, 20),
                  finished_on: Date.new(2023, 9, 7),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                ),
                hash_including(
                  started_on: Date.new(2023, 9, 8),
                  finished_on: Date.new(2024, 7, 16),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023
                )
              )
            )
          )
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
