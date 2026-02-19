describe "Real data check for user a1d38b72-4f11-490c-bee4-5b475f4b224f" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "a1d38b72-4f11-490c-bee4-5b475f4b224f",
      created_at: Time.zone.local(2021, 7, 12, 20, 3, 44),
      updated_at: Time.zone.local(2025, 11, 26, 15, 0, 50),
      ect: {
        participant_profile_id: "260c48d5-15cc-47c1-996d-26df4aa0ab14",
        created_at: Time.zone.local(2021, 7, 12, 20, 3, 44),
        updated_at: Time.zone.local(2025, 11, 26, 15, 0, 50),
        induction_start_date: Date.new(2021, 9, 6),
        induction_completion_date: Date.new(2024, 3, 28),
        pupil_premium_uplift: true,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 7, 12, 20, 3, 44)
          }
        ],
        induction_records: [
          {
            induction_record_id: "c9384512-6791-4ec5-af2c-2555c3b4a0f8",
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2022, 9, 8),
            created_at: Time.zone.local(2022, 2, 9, 10, 53, 57),
            updated_at: Time.zone.local(2022, 9, 8, 15, 52, 4),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "693f4a09-b3a0-4f68-b536-342a70206846",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "b065f02c-f422-4dfd-ad5a-a17cda972922",
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
            induction_record_id: "3d003245-b5ae-46b0-b7ea-7e95c8559594",
            start_date: Date.new(2022, 9, 8),
            end_date: Date.new(2022, 9, 8),
            created_at: Time.zone.local(2022, 9, 8, 15, 52, 4),
            updated_at: Time.zone.local(2022, 9, 8, 16, 2, 8),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "8d72c0f9-1534-470b-8d02-9e35518c6db7",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "b065f02c-f422-4dfd-ad5a-a17cda972922",
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
            induction_record_id: "4771e12c-dc2f-4921-8397-6e3dab48e155",
            start_date: Date.new(2022, 9, 8),
            end_date: Date.new(2024, 2, 3),
            created_at: Time.zone.local(2022, 9, 8, 16, 2, 8),
            updated_at: Time.zone.local(2024, 2, 3, 5, 6, 47),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "8d72c0f9-1534-470b-8d02-9e35518c6db7",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "b065f02c-f422-4dfd-ad5a-a17cda972922",
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
            induction_record_id: "8254f1e5-9cf7-4d67-af71-47e9ea1f2a3a",
            start_date: Date.new(2024, 2, 3),
            end_date: :ignore,
            created_at: Time.zone.local(2024, 2, 3, 5, 6, 47),
            updated_at: Time.zone.local(2024, 2, 3, 5, 6, 47),
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
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "b065f02c-f422-4dfd-ad5a-a17cda972922",
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
              started_on: Date.new(2024, 2, 3),
              # NOTE: we've set the finished_on using the induction_completion_date
              finished_on: Date.new(2024, 3, 28),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 2, 3),
                  finished_on: Date.new(2024, 3, 28),
                  lead_provider_info: hash_including(name: "Teach First"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2021
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
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2022, 9, 8),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2022, 9, 8)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2022, 9, 8),
              finished_on: Date.new(2022, 9, 8),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 8),
                  finished_on: Date.new(2022, 9, 8)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2022, 9, 8),
              finished_on: Date.new(2024, 2, 3),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 8),
                  finished_on: Date.new(2024, 2, 3)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 2, 3),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 2, 3),
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
