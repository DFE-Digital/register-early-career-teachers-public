describe "Real data check for user 2595d5e5-13d6-494b-a460-7b11ac9bdaa2 (induction record with corrupted date)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "2595d5e5-13d6-494b-a460-7b11ac9bdaa2",
      created_at: Time.zone.local(2022, 9, 11, 13, 27, 9),
      updated_at: Time.zone.local(2024, 12, 17, 8, 0, 21),
      mentor: {
        participant_profile_id: "fdb520f9-c482-4b94-9084-2cd964374e41",
        created_at: Time.zone.local(2022, 10, 6, 14, 24, 58),
        updated_at: Time.zone.local(2024, 12, 17, 8, 0, 20),
        mentor_completion_date: Date.new(2024, 12, 12),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2022, 6, 1),
            end_date: Date.new(2022, 12, 20),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "7cd5c1a0-2c94-405f-abab-8557f2e6eb86",
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
            start_date: Date.new(2022, 12, 1),
            end_date: Date.new(2023, 2, 20),
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "fcf2fbe5-8d13-4537-8d89-d222aeac1da1",
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
            start_date: Date.new(2022, 12, 20),
            end_date: Date.new(2022, 12, 1),
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "7cd5c1a0-2c94-405f-abab-8557f2e6eb86",
                name: "Delivery partner 1"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "b6c2e171-57ed-4842-9cb5-078cc837c0a5",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2022
            }
          },
          {
            start_date: Date.new(2023, 2, 20),
            end_date: Date.new(2023, 2, 20),
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "fcf2fbe5-8d13-4537-8d89-d222aeac1da1",
                name: "Delivery partner 2"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "3544c3cb-af64-44b7-84b1-503d7fae54ef",
              identifier: "ecf-standard-april",
              name: "ECF Standard April",
              cohort_year: 2022
            }
          },
          {
            start_date: Date.new(2023, 2, 20),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "fcf2fbe5-8d13-4537-8d89-d222aeac1da1",
                name: "Delivery partner 2"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "b6c2e171-57ed-4842-9cb5-078cc837c0a5",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2022
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 10, 6, 14, 24, 58)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 10, 6, 14, 24, 58)
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
              # NOTE: this will be converted to a stub as part of the Cleaner functionality
              #       that takes place pre-conversion
              started_on: Date.new(2022, 12, 1),
              finished_on: Date.new(2022, 12, 2),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 12, 1),
                  finished_on: Date.new(2022, 12, 2),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 2, 20),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 2, 20),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Best Practice Network"),
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

  context "when using the premium migrator", skip: "Implement premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: []
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
