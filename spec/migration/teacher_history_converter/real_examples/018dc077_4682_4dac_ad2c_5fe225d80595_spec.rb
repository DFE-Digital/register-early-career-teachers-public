describe "Real data check for user 018dc077-4682-4dac-ad2c-5fe225d80595 (schedule change)", skip: "No longer necessary" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "018dc077-4682-4dac-ad2c-5fe225d80595",
      created_at: Time.zone.local(2022, 4, 6, 13, 8, 9),
      updated_at: Time.zone.local(2025, 9, 12, 10, 28, 6),
      ect: {
        participant_profile_id: "381473ce-22a2-40ca-847d-27a5e106ea26",
        created_at: Time.zone.local(2022, 4, 6, 13, 8, 9),
        updated_at: Time.zone.local(2025, 9, 12, 10, 28, 6),
        induction_start_date: Date.new(2021, 9, 1),
        induction_completion_date: Date.new(2023, 7, 21),
        pupil_premium_uplift: true,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 4, 6, 13, 8, 9),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          }
        ],
        induction_records: [
          {
            induction_record_id: "50e44811-d99d-48a7-b316-230d1c577611",
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 9, 25),
            created_at: Time.zone.local(2022, 4, 6, 13, 8, 9),
            updated_at: Time.zone.local(2024, 1, 9, 15, 25, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "85a73b53-c02d-4325-94b4-6b5238c6d949",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "daef2be8-f1aa-4a1e-a290-ff9da053289c",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "84d07efd-ef9b-49c4-b25c-85b8b57cf8d0",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2021
            }
          },
          {
            induction_record_id: "a0f58a10-eb17-4b8a-9b07-3bd723fae337",
            start_date: Date.new(2023, 9, 25),
            end_date: :ignore,
            created_at: Time.zone.local(2023, 9, 25, 2, 38, 5),
            updated_at: Time.zone.local(2023, 9, 25, 2, 38, 5),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "daef2be8-f1aa-4a1e-a290-ff9da053289c",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "84d07efd-ef9b-49c4-b25c-85b8b57cf8d0",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2021
            }
          }
        ],
        mentor_at_school_periods: []
      },
      mentor: {
        participant_profile_id: "4f25f80b-eaed-495c-958e-0f9579b120c7",
        created_at: Time.zone.local(2024, 5, 22, 11, 41, 26),
        updated_at: Time.zone.local(2025, 9, 12, 10, 28, 6),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            induction_record_id: "47d4552f-b59b-4253-9721-d9ccee356162",
            start_date: Date.new(2023, 6, 1),
            end_date: Date.new(2024, 7, 29),
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
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "daef2be8-f1aa-4a1e-a290-ff9da053289c",
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
            induction_record_id: "dafa854c-dbf0-49ce-9ff7-4a8b6f718c48",
            start_date: Date.new(2024, 7, 29),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2023,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "daef2be8-f1aa-4a1e-a290-ff9da053289c",
                name: "Delivery partner 1"
              },
              cohort_year: 2023
            },
            schedule_info: {
              schedule_id: "c27a4bcf-0073-4b74-bf8f-d8075d39724c",
              identifier: "ecf-standard-april",
              name: "ECF Standard April",
              cohort_year: 2023
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 5, 22, 11, 41, 26),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 5, 22, 11, 41, 26)
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
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2023, 7, 21),
              finished_on: Date.new(2023, 7, 22),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 7, 21),
                  finished_on: Date.new(2023, 7, 22),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2021,
                  schedule: hash_including(
                    identifier: "ecf-standard-january",
                    name: "ECF Standard January",
                    cohort_year: 2021
                  )
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 7, 29),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 29),
                  finished_on: nil,
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023,
                  schedule: hash_including(
                    identifier: "ecf-standard-april",
                    name: "ECF Standard April",
                    cohort_year: 2023
                  )
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
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2023, 9, 25),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 9, 25),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2021,
                  schedule: hash_including(
                    identifier: "ecf-standard-january",
                    name: "ECF Standard January",
                    cohort_year: 2021
                  )
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 5, 22),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 5, 22),
                  finished_on: nil,
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023,
                  schedule: hash_including(
                    identifier: "ecf-standard-april",
                    name: "ECF Standard April",
                    cohort_year: 2023
                  )
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
