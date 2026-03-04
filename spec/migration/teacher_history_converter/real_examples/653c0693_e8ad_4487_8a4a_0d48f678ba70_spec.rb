describe "Real data check for user 653c0693-e8ad-4487-8a4a-0d48f678ba70" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "653c0693-e8ad-4487-8a4a-0d48f678ba70",
      created_at: Time.zone.local(2022, 6, 14, 15, 1, 43),
      updated_at: Time.zone.local(2025, 6, 27, 13, 11, 25),
      ect: {
        participant_profile_id: "efb71ab9-8086-4f3c-b97a-a4d4d0cfc76f",
        created_at: Time.zone.local(2022, 6, 14, 15, 1, 43),
        updated_at: Time.zone.local(2025, 6, 27, 13, 11, 25),
        induction_start_date: Date.new(2022, 9, 1),
        induction_completion_date: Date.new(2024, 7, 23),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 6, 14, 15, 1, 43)
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2023, 10, 6, 11, 18, 35)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 11, 2, 17, 12, 31)
          }
        ],
        induction_records: [
          {
            induction_record_id: "d030503e-c9b5-4bfe-9d68-47182bdd08ea",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2022, 6, 14),
            created_at: Time.zone.local(2022, 6, 14, 15, 1, 43),
            updated_at: Time.zone.local(2022, 6, 14, 15, 7, 25),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
            induction_record_id: "920b478b-a93b-497e-a9bd-d9c4811a024f",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2023, 9, 6),
            created_at: Time.zone.local(2022, 6, 14, 15, 7, 25),
            updated_at: Time.zone.local(2023, 9, 6, 13, 50, 37),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d9d646ae-a211-47eb-9ff1-ce537e1ab2f7",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
            induction_record_id: "7df5b081-0794-4740-942f-d506be4bd488",
            start_date: Date.new(2023, 9, 6),
            end_date: Date.new(2023, 10, 6),
            created_at: Time.zone.local(2023, 9, 6, 13, 50, 37),
            updated_at: Time.zone.local(2023, 10, 6, 11, 18, 35),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d50ffdea-20f2-46fa-bfe6-634d1b6fd3ab",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
            induction_record_id: "e47e046e-e16e-442f-99f5-6dceed1f7065",
            start_date: Date.new(2023, 10, 6),
            end_date: Date.new(2023, 11, 2),
            created_at: Time.zone.local(2023, 10, 6, 11, 18, 35),
            updated_at: Time.zone.local(2023, 11, 2, 17, 12, 31),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d50ffdea-20f2-46fa-bfe6-634d1b6fd3ab",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
            induction_record_id: "3b985f0a-975e-41fa-a31a-2357937b35d7",
            start_date: Date.new(2023, 11, 2),
            end_date: Date.new(2024, 7, 26),
            created_at: Time.zone.local(2023, 11, 2, 17, 12, 31),
            updated_at: Time.zone.local(2024, 7, 26, 3, 4, 54),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "d50ffdea-20f2-46fa-bfe6-634d1b6fd3ab",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
            induction_record_id: "0c10445b-4b68-41eb-84c6-1b99b8c2eb94",
            start_date: Date.new(2024, 7, 26),
            end_date: :ignore,
            created_at: Time.zone.local(2024, 7, 26, 3, 4, 54),
            updated_at: Time.zone.local(2024, 7, 26, 3, 4, 54),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f0976970-dd6d-4193-a710-ada4fd822eb7",
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
          }
        ],
        mentor_at_school_periods: []
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 7, 23),
              finished_on: Date.new(2024, 7, 24),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 23),
                  finished_on: Date.new(2024, 7, 24),
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1")
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

  context "when using the premium migrator", skip: "Implement the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2022, 6, 14),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2022, 6, 14)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 9, 6),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 9, 6)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 9, 6),
              finished_on: Date.new(2023, 10, 6),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 9, 6),
                  finished_on: Date.new(2023, 10, 6)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 10, 6),
              finished_on: Date.new(2023, 11, 2),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 10, 6),
                  finished_on: Date.new(2023, 11, 2)
                )
              )
            ),
            # this should be curtailed at 2024-07-23
            hash_including(
              started_on: Date.new(2023, 11, 2),
              finished_on: Date.new(2024, 7, 26),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 11, 2),
                  finished_on: Date.new(2024, 7, 26)
                )
              )
            ),
            # this should be snipped off as it's after the induction completion
            # date, which was 2024-07-23
            hash_including(
              started_on: Date.new(2024, 7, 26),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 26),
                  finished_on: nil
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
