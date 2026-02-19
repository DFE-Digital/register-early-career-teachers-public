describe "Real data check for user 668787fb-6c01-46ee-83bf-2e5362eba446" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "668787fb-6c01-46ee-83bf-2e5362eba446",
      created_at: Time.zone.local(2024, 7, 11, 10, 20, 40),
      updated_at: Time.zone.local(2025, 7, 17, 12, 4, 8),
      ect: {
        participant_profile_id: "cc98bcb2-b54c-4ac5-bbc5-e27c2b62ed59",
        created_at: Time.zone.local(2025, 1, 16, 11, 53, 2),
        updated_at: Time.zone.local(2025, 7, 17, 12, 4, 8),
        induction_start_date: Date.new(2025, 1, 10),
        induction_completion_date: Date.new(2025, 4, 4),
        pupil_premium_uplift: false,
        sparsity_uplift: true,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 1, 16, 11, 53, 4)
          }
        ],
        induction_records: [
          {
            induction_record_id: "e2248c37-a29e-47ce-ae49-97af2c999141",
            start_date: Date.new(2024, 9, 1),
            end_date: Date.new(2025, 1, 17),
            created_at: Time.zone.local(2025, 1, 16, 11, 53, 4),
            updated_at: Time.zone.local(2025, 1, 17, 13, 32, 33),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
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
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "5f02e94d-b0bd-4792-a114-36577e82083a",
            start_date: Date.new(2025, 1, 17),
            end_date: Date.new(2025, 1, 20),
            created_at: Time.zone.local(2025, 1, 17, 13, 32, 33),
            updated_at: Time.zone.local(2025, 1, 20, 12, 0, 51),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
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
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "89a6be9c-1884-410d-8bea-06ba16892fbf",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "5ddf4354-163c-4eec-a4d4-d676ec69d88a",
            start_date: Date.new(2025, 1, 20),
            end_date: Date.new(2025, 4, 25),
            created_at: Time.zone.local(2025, 1, 20, 12, 0, 51),
            updated_at: Time.zone.local(2025, 4, 25, 9, 4, 26),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "fbe5e836-7f0e-49cd-8d5b-1f7bd2320a8d",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "89a6be9c-1884-410d-8bea-06ba16892fbf",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "1600d34e-c00c-4f57-bf12-9d153853a45d",
            start_date: Date.new(2025, 4, 25),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 4, 25, 9, 4, 26),
            updated_at: Time.zone.local(2025, 4, 25, 9, 4, 26),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
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
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "89a6be9c-1884-410d-8bea-06ba16892fbf",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2024
            }
          }
        ],
        mentor_at_school_periods: []
      },
      mentor: {
        participant_profile_id: "930d4f6c-5ccf-4a79-821e-e41a49cbc678",
        created_at: Time.zone.local(2024, 7, 11, 10, 20, 40),
        updated_at: Time.zone.local(2025, 7, 17, 12, 4, 8),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2024, 6, 1),
            end_date: Date.new(2025, 1, 14),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
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
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            start_date: Date.new(2025, 1, 14),
            end_date: Date.new(2025, 5, 8),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            start_date: Date.new(2025, 5, 8),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2024,
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "51702660-b0a5-42d1-9614-768aeb7d2d04",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 7, 11, 10, 20, 40)
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2025, 1, 14, 9, 30, 12)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 5, 8, 14, 47, 37)
          }
        ]
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
              # NOTE: here, the final induction record above has been converted to a stub because
              #       the induction_completion_date is before the start's end date
              started_on: Date.new(2025, 4, 4),
              finished_on: Date.new(2025, 4, 5),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 4, 4),
                  finished_on: Date.new(2025, 4, 5),
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2024
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2025, 5, 8),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 5, 8),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2024
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
              started_on: Date.new(2024, 9, 1),
              finished_on: Date.new(2025, 1, 17),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 9, 1),
                  finished_on: Date.new(2025, 1, 17)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 1, 17),
              finished_on: Date.new(2025, 1, 20),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 1, 17),
                  finished_on: Date.new(2025, 1, 20)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 1, 20),
              finished_on: Date.new(2025, 4, 25),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 1, 20),
                  finished_on: Date.new(2025, 4, 25)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 4, 25),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 4, 25),
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
