describe "Real data check for user d283a5c2-ab76-465e-b261-cb55cf946f00" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "d283a5c2-ab76-465e-b261-cb55cf946f00",
      created_at: Time.zone.local(2024, 7, 19, 9, 21, 40),
      updated_at: Time.zone.local(2025, 9, 15, 12, 11, 23),
      ect: {
        participant_profile_id: "a0e29b7f-ee20-4bda-9e55-bf1ba7d2f02a",
        created_at: Time.zone.local(2024, 7, 19, 9, 21, 40),
        updated_at: Time.zone.local(2025, 9, 15, 12, 11, 23),
        induction_start_date: Date.new(2024, 9, 2),
        induction_completion_date: :ignore,
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 7, 19, 9, 21, 40)
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2025, 8, 21, 16, 1, 13)
          }
        ],
        induction_records: [
          {
            induction_record_id: "c2fc9f49-4af7-49b3-a0a8-0fca30fcc883",
            start_date: Date.new(2024, 6, 1),
            end_date: Date.new(2024, 7, 22),
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "7f8ba241-99f5-4b96-a8ee-0b50f2a330f8",
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
            induction_record_id: "1c2e83fc-1585-486b-a785-d28e3d5c5d0c",
            start_date: Date.new(2024, 7, 22),
            end_date: Date.new(2025, 8, 21),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "932eedaf-cda6-4078-8510-5dc600b88f3a",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "7f8ba241-99f5-4b96-a8ee-0b50f2a330f8",
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
            induction_record_id: "c08e63ee-22c4-4340-8a77-a1d060949188",
            start_date: Date.new(2025, 8, 6),
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
            mentor_profile_id: "932eedaf-cda6-4078-8510-5dc600b88f3a",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "da8fef08-80b3-44c6-a482-d2969410fdfb",
                name: "Delivery partner 2"
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
            induction_record_id: "554f599d-2aa9-423c-a37c-f6c0454d08a5",
            start_date: Date.new(2025, 8, 21),
            end_date: Date.new(2025, 8, 6),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "932eedaf-cda6-4078-8510-5dc600b88f3a",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "7f8ba241-99f5-4b96-a8ee-0b50f2a330f8",
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
        mentor_at_school_periods: [
          {
            mentor_at_school_period_id: SecureRandom.uuid,
            started_on: Date.new(2025, 8, 4),
            finished_on: Date.new(2025, 8, 5),
            school: {
              urn: "100001",
              name: "School 1"
            },
            teacher: {
              trn: "2222222",
              api_mentor_training_record_id: "932eedaf-cda6-4078-8510-5dc600b88f3a"
            }
          },
          {
            mentor_at_school_period_id:,
            started_on: Date.new(2025, 8, 6),
            finished_on: :ignore,
            school: {
              urn: "100001",
              name: "School 1"
            },
            teacher: {
              trn: "2222222",
              api_mentor_training_record_id: "932eedaf-cda6-4078-8510-5dc600b88f3a"
            }
          }
        ]
        # mentor_at_school_periods:
        # TeacherHistoryConverter
        #   .new(ecf1_teacher_history: ecf1_mentor_history)
        #   .convert_to_ecf2!
        #   .mentor_at_school_periods
        #   .map do |ec2_mentor_at_school_period|
        #      ec2_mentor_at_school_period
        #        .to_h
        #        .except(:email, :training_periods)
        #        .merge(mentor_at_school_period_id: SecureRandom.uuid,
        #               teacher: {
        #                 api_mentor_training_record_id: ecf1_mentor_history.mentor.participant_profile_id,
        #                 trn: ecf1_mentor_history.mentor.teacher.trn
        #               })
        # end
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:ecf1_mentor_history) do
    ECF1TeacherHistory.from_hash(
      {
        trn: "2222222",
        full_name: "A Mentor",
        user_id: "9200616b-0c71-4f9f-96fe-a759fcb55f9a",
        created_at: Time.zone.local(2022, 9, 1, 14, 54, 58),
        updated_at: Time.zone.local(2025, 9, 15, 11, 11, 23),
        mentor: {
          participant_profile_id: "932eedaf-cda6-4078-8510-5dc600b88f3a",
          created_at: Time.zone.local(2024, 7, 22, 9, 1, 25),
          updated_at: Time.zone.local(2025, 9, 15, 11, 11, 23),
          mentor_completion_date: :ignore,
          mentor_completion_reason: :ignore,
          payments_frozen_cohort_start_year: false,
          states: [
            {
              state: "active",
              reason: :ignore,
              created_at: Time.zone.local(2024, 7, 22, 9, 1, 25)
            },
            {
              state: "withdrawn",
              reason: "other",
              created_at: Time.zone.local(2025, 8, 21, 16, 0, 58)
            }
          ],
          induction_records: [
            {
              induction_record_id: "09daac5d-27e5-49a3-b72e-eb3f6440f91e",
              start_date: Date.new(2024, 6, 1),
              end_date: Date.new(2025, 8, 21),
              training_programme: "full_induction_programme",
              cohort_year: 2024,
              school: {
                urn: "100001",
                name: "School 1"
              },
              induction_status: "changed",
              training_status: "active",
              preferred_identity_email: "b.teacher@example.com",
              mentor_profile_id: :ignore,
              training_provider_info: {
                lead_provider: {
                  ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                  name: "Best Practice Network"
                },
                delivery_partner: {
                  ecf1_id: "e4a39518-7e0c-456b-ab76-be02cb19e952",
                  name: "Delivery partner 4"
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
              induction_record_id: "7b816792-06da-4960-885a-f450c152cb7f",
              start_date: Date.new(2025, 8, 6),
              end_date: :ignore,
              training_programme: "full_induction_programme",
              cohort_year: 2024,
              school: {
                urn: "100001",
                name: "School 1"
              },
              induction_status: "active",
              training_status: "active",
              preferred_identity_email: "b.teacher@example.com",
              mentor_profile_id: :ignore,
              training_provider_info: {
                lead_provider: {
                  ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                  name: "Ambition Institute"
                },
                delivery_partner: {
                  ecf1_id: "c823ebe1-e93f-4541-833c-7b7290e38ba1",
                  name: "Delivery partner 3"
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
              induction_record_id: "6d54cb13-75b4-449a-8ae1-75f8f4a65095",
              start_date: Date.new(2025, 8, 21),
              end_date: Date.new(2025, 8, 6),
              training_programme: "full_induction_programme",
              cohort_year: 2024,
              school: {
                urn: "100001",
                name: "School 1"
              },
              induction_status: "changed",
              training_status: "withdrawn",
              preferred_identity_email: "b.teacher@example.com",
              mentor_profile_id: :ignore,
              training_provider_info: {
                lead_provider: {
                  ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                  name: "Best Practice Network"
                },
                delivery_partner: {
                  ecf1_id: "e4a39518-7e0c-456b-ab76-be02cb19e952",
                  name: "Delivery partner 4"
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
          ]
        }
      }
    )
  end

  let(:mentor_at_school_period_id) { SecureRandom.uuid }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            # stub record
            hash_including(
              started_on: Date.new(2025, 8, 4),
              finished_on: Date.new(2025, 8, 5),
              school: hash_including(name: "School 1"),
              mentorship_periods: [],
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 4),
                  finished_on: Date.new(2025, 8, 5),
                  lead_provider_info: hash_including(name: "Best Practice Network"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2024,
                  withdrawn_at: Time.zone.local(2025, 8, 21, 16, 1, 13),
                  withdrawal_reason: "other",
                )
              )
            ),
            # ongoing record
            hash_including(
              started_on: Date.new(2025, 8, 6),
              finished_on: nil,
              school: hash_including(name: "School 1"),
              mentorship_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 6),
                  finished_on: nil,
                  ecf_start_induction_record_id: "c08e63ee-22c4-4340-8a77-a1d060949188",
                  ecf_end_induction_record_id: "c08e63ee-22c4-4340-8a77-a1d060949188",
                  mentor_at_school_period_id:
                )
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 6),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
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

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 6, 1),
              finished_on: Date.new(2024, 7, 22),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 1),
                  finished_on: Date.new(2024, 7, 22)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 7, 22),
              finished_on: Date.new(2025, 8, 21),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 7, 22),
                  finished_on: Date.new(2025, 8, 21)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 8, 6),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 6),
                  finished_on: nil
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 8, 21),
              finished_on: Date.new(2025, 8, 6),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 21),
                  finished_on: Date.new(2025, 8, 6)
                )
              )
            )
          )
        )
      }
    end

    it "matches the expected output", skip: "Implement premium migrator" do
      expect(actual_output).to include(expected_output)
    end
  end
end
