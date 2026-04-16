describe "Real data check for user c51e6a24-b9b6-4088-9f01-1112d4edb32d (deletions and patches from CSV)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "c51e6a24-b9b6-4088-9f01-1112d4edb32d",
      created_at: Time.zone.local(2022, 7, 12, 9, 49, 38),
      updated_at: Time.zone.local(2025, 7, 2, 12, 57, 10),
      ect: {
        participant_profile_id: "1d91b084-030e-485d-996e-92fbf2e46f51",
        created_at: Time.zone.local(2022, 7, 12, 9, 49, 38),
        updated_at: Time.zone.local(2025, 7, 2, 12, 57, 10),
        induction_start_date: Date.new(2022, 9, 6),
        induction_completion_date: Date.new(2024, 7, 19),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 12, 9, 49, 38),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 12, 9, 49, 38),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 19, 15, 14, 19),
            cpd_lead_provider_id: :ignore
          }
        ],
        induction_records: [
          {
            # NOTE: deleted in CSV
            induction_record_id: "e262935c-9911-4cc1-a98d-b10f7b4cfe2e",
            start_date: Date.new(2022, 9, 5),
            end_date: Date.new(2023, 9, 20),
            created_at: Time.zone.local(2022, 7, 12, 9, 49, 38),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
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
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ce21c98f-6ecd-4ae0-8bbf-890d32045d47",
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
            induction_record_id: "dda9c2ae-716f-42a9-9985-e5583295a1de",
            start_date: Date.new(2022, 9, 5),
            # NOTE: end_date patched in CSV
            end_date: Date.new(2023, 9, 20),
            created_at: Time.zone.local(2022, 7, 12, 9, 56, 36),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "32c0a039-c68e-446d-83d8-fafb148d59de",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ce21c98f-6ecd-4ae0-8bbf-890d32045d47",
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
            induction_record_id: "68d48bc8-f540-49f7-a86f-17f6df89aaaf",
            start_date: Date.new(2022, 12, 12),
            # NOTE: end_date patched_in CSV
            end_date: Date.new(2023, 9, 20),
            created_at: Time.zone.local(2022, 12, 12, 21, 29, 10),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "9440e513-577c-4eeb-83dc-7c9ca9ac3021",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ce21c98f-6ecd-4ae0-8bbf-890d32045d47",
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
            induction_record_id: "5853db0f-1490-40b0-b90b-87704320c23a",
            start_date: Date.new(2023, 3, 28),
            # NOTE: end_date patched in CSV
            end_date: Date.new(2023, 9, 20),
            created_at: Time.zone.local(2023, 3, 28, 13, 43, 37),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 32),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "c332f5df-603f-44e2-bb85-484767ace534",
            appropriate_body: {
              ecf1_id: "106bf66a-df14-4c06-9491-c48722a9cbcf",
              name: "Coventry"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ce21c98f-6ecd-4ae0-8bbf-890d32045d47",
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
            induction_record_id: "6e4a4d3d-cb96-497a-97f6-884fd99040a2",
            start_date: Date.new(2023, 9, 1),
            end_date: Date.new(2023, 10, 26),
            created_at: Time.zone.local(2023, 9, 19, 15, 14, 19),
            updated_at: Time.zone.local(2023, 10, 26, 10, 37, 21),
            training_programme: "core_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {
              ecf1_id: "fa1b2e36-0755-4644-8c77-8484d18a5551",
              name: "Sandwell"
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
            induction_record_id: "2808b797-3948-4061-8346-79f57c74a829",
            start_date: Date.new(2023, 9, 20),
            end_date: Date.new(2023, 10, 26),
            created_at: Time.zone.local(2023, 9, 20, 9, 14, 18),
            updated_at: Time.zone.local(2023, 10, 26, 10, 37, 21),
            training_programme: "core_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "2b73b278-b222-40ce-bcad-4921d0a116ae",
            appropriate_body: {
              ecf1_id: "fa1b2e36-0755-4644-8c77-8484d18a5551",
              name: "Sandwell"
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
            # NOTE: deleted in CSV
            induction_record_id: "451e9135-8363-4dc3-83c9-d46da1853dc8",
            start_date: Date.new(2023, 9, 20),
            end_date: Date.new(2022, 7, 12),
            created_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
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
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "2a4679dc-6c5d-4127-9f9a-53732ab3a052",
                name: "Delivery partner 2"
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
            # NOTE: deleted in CSV
            induction_record_id: "54306581-0c86-442a-baa9-eac23e17b85b",
            start_date: Date.new(2023, 9, 20),
            end_date: Date.new(2022, 12, 12),
            created_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 31),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "32c0a039-c68e-446d-83d8-fafb148d59de",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "2a4679dc-6c5d-4127-9f9a-53732ab3a052",
                name: "Delivery partner 2"
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
            # NOTE: deleted in CSV
            induction_record_id: "e8e82e42-8696-4e12-84de-0948192e7000",
            start_date: Date.new(2023, 9, 20),
            end_date: Date.new(2023, 3, 28),
            created_at: Time.zone.local(2023, 9, 20, 13, 31, 32),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 32),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "9440e513-577c-4eeb-83dc-7c9ca9ac3021",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "2a4679dc-6c5d-4127-9f9a-53732ab3a052",
                name: "Delivery partner 2"
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
            induction_record_id: "e5951453-9ccd-4de6-85f8-b511c52c3046",
            start_date: Date.new(2023, 9, 20),
            end_date: Date.new(2023, 7, 21),
            created_at: Time.zone.local(2023, 9, 20, 13, 31, 32),
            updated_at: Time.zone.local(2023, 9, 20, 13, 31, 32),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "c332f5df-603f-44e2-bb85-484767ace534",
            appropriate_body: {
              ecf1_id: "106bf66a-df14-4c06-9491-c48722a9cbcf",
              name: "Coventry"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "2a4679dc-6c5d-4127-9f9a-53732ab3a052",
                name: "Delivery partner 2"
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
            induction_record_id: "3e0d30a7-9350-4853-983b-01f737f6ce06",
            start_date: Date.new(2023, 10, 26),
            end_date: Date.new(2024, 7, 20),
            created_at: Time.zone.local(2023, 10, 26, 10, 37, 21),
            updated_at: Time.zone.local(2024, 7, 20, 2, 59, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "2b73b278-b222-40ce-bcad-4921d0a116ae",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "1cb062eb-3a54-4f55-a110-898a8dd1855f",
                name: "Delivery partner 3"
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
            # NOTE: deleted in CSV
            induction_record_id: "b28269a3-a640-43cc-87c0-6b755a43986b",
            start_date: Date.new(2023, 10, 26),
            end_date: Date.new(2023, 9, 20),
            created_at: Time.zone.local(2023, 10, 26, 10, 37, 21),
            updated_at: Time.zone.local(2023, 10, 26, 10, 37, 21),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {
              ecf1_id: "fa1b2e36-0755-4644-8c77-8484d18a5551",
              name: "Sandwell"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "1cb062eb-3a54-4f55-a110-898a8dd1855f",
                name: "Delivery partner 3"
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
            induction_record_id: "123a1bf1-3caa-4a24-93c2-2626753447e8",
            start_date: Date.new(2024, 7, 20),
            end_date: :ignore,
            created_at: Time.zone.local(2024, 7, 20, 2, 59, 11),
            updated_at: Time.zone.local(2024, 7, 20, 2, 59, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
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
                ecf1_id: "1cb062eb-3a54-4f55-a110-898a8dd1855f",
                name: "Delivery partner 3"
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
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2023, 3, 28),
              finished_on: Date.new(2023, 8, 31),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 3, 28),
                  finished_on: Date.new(2023, 8, 31),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            # hash_including(
            #   started_on: Date.new(2023, 7, 21),
            #   finished_on: Date.new(2023, 7, 22),
            #   school: hash_including(urn: "100001", name: "School 1"),
            #   training_periods: array_including(
            #     hash_including(
            #       started_on: Date.new(2023, 7, 21),
            #       finished_on: Date.new(2023, 7, 22),
            #       training_programme: "provider_led",
            #       lead_provider_info: hash_including(name: "Ambition Institute"),
            #       delivery_partner_info: hash_including(name: "Delivery partner 2"),
            #       contract_period_year: 2022
            #     )
            #   )
            # ),
            hash_including(
              started_on: Date.new(2023, 9, 20),
              finished_on: Date.new(2023, 10, 26),
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 9, 20),
                  finished_on: Date.new(2023, 10, 26),
                  training_programme: "school_led",
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 7, 19),
              finished_on: Date.new(2024, 7, 20),
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 19),
                  finished_on: Date.new(2024, 7, 20),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 3"),
                  contract_period_year: 2022
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
              started_on: Date.new(2022, 9, 5),
              finished_on: Date.new(2023, 8, 31),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 5),
                  finished_on: Date.new(2023, 8, 31),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 9, 1),
              finished_on: Date.new(2024, 7, 20),
              school: hash_including(urn: "100002", name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 9, 1),
                  finished_on: Date.new(2023, 10, 25),
                  training_programme: "school_led",
                  contract_period_year: 2022
                ),
                hash_including(
                  started_on: Date.new(2023, 10, 26),
                  finished_on: Date.new(2024, 7, 20),
                  training_programme: "provider_led",
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 3"),
                  contract_period_year: 2022
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
