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
            start_date: Time.zone.local(2024, 6, 1, 1, 0, 0),
            end_date: Time.zone.local(2024, 7, 22, 11, 9, 46),
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
            start_date: Time.zone.local(2024, 7, 22, 11, 9, 46),
            end_date: Time.zone.local(2025, 8, 21, 16, 1, 13),
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
            start_date: Time.zone.local(2025, 8, 6, 14, 6, 51),
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
            start_date: Time.zone.local(2025, 8, 21, 16, 1, 13),
            end_date: Time.zone.local(2025, 8, 6, 14, 6, 51),
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
            # stub record
            hash_including(
              started_on: Date.new(2025, 8, 4),
              finished_on: Date.new(2025, 8, 5),
              school: hash_including(name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 8, 4),
                  finished_on: Date.new(2025, 8, 5),
                  lead_provider_info: hash_including(name: "Best Practice Network"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2024
                )
              )
            ),
            # ongoing record
            hash_including(
              started_on: Date.new(2025, 8, 6),
              finished_on: nil,
              school: hash_including(name: "School 1"),
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
