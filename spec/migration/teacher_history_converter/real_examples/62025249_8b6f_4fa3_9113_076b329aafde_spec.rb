describe "Real data check for user 62025249-8b6f-4fa3-9113-076b329aafde (mentor period has no training provider info)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "62025249-8b6f-4fa3-9113-076b329aafde",
      created_at: Time.zone.local(2022, 9, 20, 11, 55, 26),
      updated_at: Time.zone.local(2025, 7, 9, 11, 11, 34),
      mentor: {
        participant_profile_id: "3b4a4e01-2e1c-47f6-afda-45780f8e9045",
        created_at: Time.zone.local(2022, 9, 20, 11, 55, 26),
        updated_at: Time.zone.local(2025, 7, 9, 11, 11, 34),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 11, 6),
            training_programme: "core_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {},
            schedule_info: {
              schedule_id: "80e0a108-d5f7-433f-8c56-27b436b4dea8",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2023, 11, 6),
            end_date: Date.new(2023, 11, 8),
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
            training_provider_info: {},
            schedule_info: {
              schedule_id: "80e0a108-d5f7-433f-8c56-27b436b4dea8",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2023, 11, 6),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2024, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2023, 11, 8),
            end_date: Date.new(2023, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
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
            start_date: Date.new(2024, 11, 8),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "531ca788-b8c7-4aad-9e4a-ad9f766e44e5",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "4cc26452-e018-4671-aac2-1d3f572a6aa1",
              identifier: "ecf-extended-september",
              name: "ECF Extended September",
              cohort_year: 2024
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 9, 20, 11, 55, 26)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 9, 20, 11, 55, 26)
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
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2023, 11, 6),
              finished_on: Date.new(2023, 11, 7),
              training_periods: array_including(
                hash_including(
                  training_programme: "provider_led",
                  lead_provider_info: {},
                  delivery_partner_info: {},
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 11, 8),
              finished_on: Date.new(2023, 11, 9),
              training_periods: array_including(
                hash_including(
                  training_programme: "provider_led",
                  started_on: Date.new(2023, 11, 8),
                  finished_on: Date.new(2023, 11, 9),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 11, 8),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  training_programme: "provider_led",
                  started_on: Date.new(2024, 11, 8),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
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
          trn: "1111111"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
