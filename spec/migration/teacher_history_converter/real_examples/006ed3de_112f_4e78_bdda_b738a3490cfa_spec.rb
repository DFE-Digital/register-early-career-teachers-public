describe "Real data check for user 006ed3de-112f-4e78-bdda-b738a3490cfa" do
  # this teacher had two periods of mentorship with different mentors:
  #
  # 160bdffd-ff0d-42ec-9270-febd9f594155 (see 81f8f951_a339_447e_a4d6_f10453d29e5d_spec.rb)
  # 410e7dfe-7561-4149-aad5-5bfdd099d04c (see c82e38f1_920b_4ad0_98a3_5d69ee7f7b83_spec.rb)

  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "006ed3de-112f-4e78-bdda-b738a3490cfa",
      created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
      updated_at: Time.zone.local(2025, 1, 31, 6, 15, 25),
      ect: {
        participant_profile_id: "ef41f4ff-d8c6-4800-a32c-32b429bb694d",
        created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
        updated_at: Time.zone.local(2025, 1, 31, 6, 15, 25),
        induction_start_date: Date.new(2022, 9, 1),
        induction_completion_date: Date.new(2024, 7, 22),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
            cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
            cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 4, 20, 3, 42),
            cpd_lead_provider_id: :ignore
          }
        ],
        induction_records: [
          {
            induction_record_id: "786360a5-c3e8-428a-8c54-e7d022022b8d",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2023, 9, 1),
            created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
            updated_at: Time.zone.local(2023, 9, 4, 20, 3, 42),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "410e7dfe-7561-4149-aad5-5bfdd099d04c",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "bed7d1dc-a723-49f5-8236-711448e1011f",
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
            induction_record_id: "c39361d7-0232-434e-aef6-a8a5860f2b5b",
            start_date: Date.new(2023, 9, 1),
            end_date: Date.new(2023, 9, 14),
            created_at: Time.zone.local(2023, 9, 4, 20, 3, 42),
            updated_at: Time.zone.local(2023, 9, 14, 10, 51, 50),
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
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "f9108038-3a90-46f0-a780-737d2838b5c9",
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
            induction_record_id: "8484ae2d-0197-424d-9acb-f55f4008a9da",
            start_date: Date.new(2023, 9, 14),
            end_date: Date.new(2024, 8, 20),
            created_at: Time.zone.local(2023, 9, 14, 10, 51, 50),
            updated_at: Time.zone.local(2024, 8, 20, 3, 50, 29),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "160bdffd-ff0d-42ec-9270-febd9f594155",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "f9108038-3a90-46f0-a780-737d2838b5c9",
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
            induction_record_id: "f9fe7321-7afc-42c5-ade3-8082c2fec88e",
            start_date: Date.new(2024, 8, 20),
            end_date: :ignore,
            created_at: Time.zone.local(2024, 8, 20, 3, 50, 29),
            updated_at: Time.zone.local(2024, 8, 20, 3, 50, 29),
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
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "f9108038-3a90-46f0-a780-737d2838b5c9",
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

    let(:mentor_at_school_periods) do
      [
        {
          # This teacher's data is covered by c82e38f1_920b_4ad0_98a3_5d69ee7f7b83_spec.rb
          #
          # This record was imported using the economy migrator so only the latest induction
          # record is present, resulting in 0 overlap with the ECT and therefore no mentorship
          # periods
          mentor_at_school_period_id: 1,
          started_on: Date.new(2024, 1, 8),
          finished_on: nil,
          school: { urn: "100001", name: "School 1" },
          teacher: { trn: "9000009", api_mentor_training_record_id: "410e7dfe-7561-4149-aad5-5bfdd099d04c" }
        }
      ]
    end

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          trs_induction_start_date: Date.new(2022, 9, 1),
          trs_induction_completed_date: Date.new(2024, 7, 22),
          ect_at_school_periods: array_including(
            hash_including(
              school: hash_including(urn: "100001", name: "School 1"),
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 9, 1),
              mentorship_periods: [],
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 9, 1),
                  lead_provider_info: hash_including(name: "Education Development Trust"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              # NOTE: here, the final induction record above has been converted to a stub because
              #       the induction_completion_date is before the start's end date
              school: hash_including(urn: "100002", name: "School 2"),
              started_on: Date.new(2024, 7, 22),
              finished_on: Date.new(2024, 7, 23),
              mentorship_periods: [],
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 22),
                  finished_on: Date.new(2024, 7, 23),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
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

    let(:mentor_at_school_periods) do
      [
        {
          # This teacher's data is covered by c82e38f1_920b_4ad0_98a3_5d69ee7f7b83_spec.rb
          #
          # When this record was imported using the premium migrator (all the induction records),
          # we have an overlap with the ECT and therefore a mentorship period
          mentor_at_school_period_id: 1,
          started_on: Date.new(2022, 6, 1),
          finished_on: nil,
          school: { urn: "100001", name: "School 1" },
          teacher: { trn: "9000009", api_mentor_training_record_id: "410e7dfe-7561-4149-aad5-5bfdd099d04c" }
        }
      ]
    end

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: [
            hash_including(
              school: hash_including(urn: "100001", name: "School 1"),
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 9, 1),
              mentorship_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 9, 1),
                  mentor_at_school_period_id: 1
                )
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 9, 1),
                  lead_provider_info: hash_including(name: "Education Development Trust"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            # NOTE: 2nd induction record starts after the induction completion date so not migrated
          ]
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
