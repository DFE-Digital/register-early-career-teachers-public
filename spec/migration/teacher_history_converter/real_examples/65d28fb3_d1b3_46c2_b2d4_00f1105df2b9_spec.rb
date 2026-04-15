describe "Real data check for user 65d28fb3-d1b3-46c2-b2d4-00f1105df2b9 (patched start_date from CSV)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "65d28fb3-d1b3-46c2-b2d4-00f1105df2b9",
      created_at: Time.zone.local(2023, 7, 16, 14, 48, 15),
      updated_at: Time.zone.local(2026, 3, 11, 1, 19, 17),
      ect: {
        participant_profile_id: "6294d4a5-6375-4338-9166-ec56e5de8729",
        created_at: Time.zone.local(2023, 7, 16, 14, 48, 16),
        updated_at: Time.zone.local(2026, 3, 11, 1, 19, 17),
        induction_start_date: Date.new(2023, 9, 1),
        induction_completion_date: Date.new(2025, 7, 18),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 16, 14, 48, 16),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 16, 14, 48, 16),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          }
        ],
        induction_records: [
          {
            induction_record_id: "ba487f79-d7d1-46ba-9e51-a6a0c0145e69",
            start_date: Date.new(2023, 6, 1),
            end_date: Date.new(2023, 9, 6),
            created_at: Time.zone.local(2023, 7, 16, 14, 48, 16),
            updated_at: Time.zone.local(2023, 9, 6, 8, 48, 28),
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
            appropriate_body: {
              ecf1_id: "3fbad505-80d8-4aed-b5cb-141270b3e5c7",
              name: "London District East Teaching School Hub (Tollgate Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "4bcd99d6-1c09-4173-9b92-2f67c02876d0",
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
            induction_record_id: "e98d519a-5eb2-48ae-a92f-e91b8cdbae52",
            start_date: Date.new(2023, 9, 6),
            end_date: Date.new(2024, 2, 26),
            created_at: Time.zone.local(2023, 9, 6, 8, 48, 28),
            updated_at: Time.zone.local(2024, 2, 26, 15, 41, 12),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "9ffd2f7a-366a-4ab7-8d42-e8f9c99889a7",
            appropriate_body: {
              ecf1_id: "3fbad505-80d8-4aed-b5cb-141270b3e5c7",
              name: "London District East Teaching School Hub (Tollgate Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "4bcd99d6-1c09-4173-9b92-2f67c02876d0",
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
            induction_record_id: "35d5d92a-dfee-4098-91ca-ee7dbb763d57",
            start_date: Date.new(2024, 2, 26),
            end_date: Date.new(2024, 2, 26),
            created_at: Time.zone.local(2024, 2, 26, 15, 41, 12),
            updated_at: Time.zone.local(2024, 2, 26, 15, 41, 41),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "935710b6-8260-4c9a-97ac-fb3b0b60a038",
            appropriate_body: {
              ecf1_id: "3fbad505-80d8-4aed-b5cb-141270b3e5c7",
              name: "London District East Teaching School Hub (Tollgate Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "4bcd99d6-1c09-4173-9b92-2f67c02876d0",
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
            induction_record_id: "588133a8-49a3-4e03-ab15-3734e63ba0e1",
            start_date: Date.new(2024, 2, 26),
            end_date: Date.new(2024, 8, 31),
            created_at: Time.zone.local(2024, 2, 26, 15, 41, 41),
            updated_at: Time.zone.local(2024, 7, 17, 11, 48, 30),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "fd3a6fe2-8237-4898-a5a6-d7a0ea8bf5b2",
            appropriate_body: {
              ecf1_id: "3fbad505-80d8-4aed-b5cb-141270b3e5c7",
              name: "London District East Teaching School Hub (Tollgate Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "4bcd99d6-1c09-4173-9b92-2f67c02876d0",
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
            induction_record_id: "669abf5d-e052-4c86-911b-2fb92ed1169c",
            start_date: Date.new(2024, 9, 1),
            end_date: Date.new(2024, 9, 11),
            created_at: Time.zone.local(2024, 9, 5, 11, 38, 48),
            updated_at: Time.zone.local(2024, 9, 11, 17, 47, 54),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {
              ecf1_id: "6b433d0a-2244-4132-931f-c7c17b8fa68c",
              name: "Central London Teaching School Hub (Paddington Academy)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "ee1cb21d-f486-45dc-87a6-430495da1934",
                name: "Delivery partner 2"
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
            induction_record_id: "322edc15-0b02-4545-bb89-c381b6370b7f",
            start_date: Date.new(2024, 9, 11),
            end_date: Date.new(2025, 9, 3),
            created_at: Time.zone.local(2024, 9, 11, 17, 47, 54),
            updated_at: Time.zone.local(2025, 9, 3, 1, 12, 14),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "9ca4ecb3-900e-4212-8eb9-c53e921d47e1",
            appropriate_body: {
              ecf1_id: "6b433d0a-2244-4132-931f-c7c17b8fa68c",
              name: "Central London Teaching School Hub (Paddington Academy)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "ee1cb21d-f486-45dc-87a6-430495da1934",
                name: "Delivery partner 2"
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
            induction_record_id: "5224ed26-53b8-4969-9098-ced505f763da",
            start_date: Date.new(2025, 9, 3),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 9, 3, 1, 12, 14),
            updated_at: Time.zone.local(2025, 9, 3, 1, 12, 14),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {
              ecf1_id: "6b433d0a-2244-4132-931f-c7c17b8fa68c",
              name: "Central London Teaching School Hub (Paddington Academy)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "ee1cb21d-f486-45dc-87a6-430495da1934",
                name: "Delivery partner 2"
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
      },
      mentor: {
        participant_profile_id: "837ed9fe-82a9-43e7-a594-02c7b1ec4abe",
        created_at: Time.zone.local(2025, 9, 11, 10, 29, 2),
        updated_at: Time.zone.local(2025, 9, 11, 22, 22, 47),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            induction_record_id: "ec755769-29be-4050-b4d6-f8d3edd2eb28",
            # NOTE: this is the date that is patched from the CSV
            start_date: Date.new(2025, 6, 1),
            end_date: Date.new(2025, 9, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2025,
            school: {
              urn: "100002",
              name: "School 2"
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
                ecf1_id: "ee1cb21d-f486-45dc-87a6-430495da1934",
                name: "Delivery partner 2"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          },
          {
            induction_record_id: "cc23d5e6-4644-4a78-a360-938ab7772205",
            start_date: Date.new(2025, 9, 11),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2025,
            school: {
              urn: "100002",
              name: "School 2"
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
                ecf1_id: "ee1cb21d-f486-45dc-87a6-430495da1934",
                name: "Delivery partner 2"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "f2608c3e-9405-4fe9-a6c4-1b1fb88bc53d",
              identifier: "ecf-replacement-september",
              name: "ECF Replacement September",
              cohort_year: 2025
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 9, 11, 10, 29, 2),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100002",
              name: "School 2"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2025, 9, 11, 10, 29, 2)
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
              started_on: Date.new(2024, 2, 26),
              finished_on: Date.new(2024, 8, 31),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 2, 26),
                  finished_on: Date.new(2024, 8, 31),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 7, 18),
              finished_on: Date.new(2025, 7, 19),
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 7, 18),
                  finished_on: Date.new(2025, 7, 19),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2023
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2025, 9, 11),
              finished_on: nil,
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 11),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2025
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
              started_on: Date.new(2023, 6, 1),
              finished_on: Date.new(2024, 8, 31),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 6, 1),
                  finished_on: Date.new(2024, 8, 31),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 9, 1),
              finished_on: Date.new(2025, 9, 3),
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 9, 1),
                  finished_on: Date.new(2025, 9, 3),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2023
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              # NOTE: this is the patched date
              started_on: Date.new(2025, 9, 1),
              finished_on: nil,
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2025
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
