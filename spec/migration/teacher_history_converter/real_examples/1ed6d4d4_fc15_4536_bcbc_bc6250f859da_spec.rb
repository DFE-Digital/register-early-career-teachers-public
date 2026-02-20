describe "Real data check for user 1ed6d4d4-fc15-4536-bcbc-bc6250f859da (with a withdrawal date and reason)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "1ed6d4d4-fc15-4536-bcbc-bc6250f859da",
      created_at: Time.zone.local(2023, 7, 20, 12, 30, 12),
      updated_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
      ect: {
        participant_profile_id: "e5d8ea8c-3aee-4bd7-80ab-5618e18db1b7",
        created_at: Time.zone.local(2023, 7, 20, 12, 30, 12),
        updated_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
        induction_start_date: Date.new(2023, 9, 1),
        induction_completion_date: Date.new(2025, 7, 22),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 20, 12, 30, 12)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 20, 12, 30, 12)
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
            cpd_lead_provider_id: "dfad2a9c-527d-4d71-ae9a-492ab307e6c3"
          }
        ],
        induction_records: [
          {
            induction_record_id: "ed357d86-c129-48a3-90f0-1a0430dfb5d1",
            start_date: Date.new(2023, 6, 1),
            end_date: Date.new(2025, 7, 31),
            created_at: Time.zone.local(2023, 7, 20, 12, 30, 12),
            updated_at: Time.zone.local(2025, 7, 31, 4, 30, 17),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "ac3d7ef4-4057-445e-98ef-ddce62f3d71c",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "e531caea-a7a8-495d-b061-f914d96cf4ba",
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
            induction_record_id: "5598d47f-5a66-48c6-9221-87d5a7b99a41",
            start_date: Date.new(2025, 7, 31),
            end_date: Date.new(2025, 9, 4),
            created_at: Time.zone.local(2025, 7, 31, 4, 30, 17),
            updated_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
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
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "e531caea-a7a8-495d-b061-f914d96cf4ba",
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
            induction_record_id: "c56730ad-f14e-4fee-a581-5a0ce0567908",
            start_date: Date.new(2025, 9, 4),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
            updated_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "completed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "e531caea-a7a8-495d-b061-f914d96cf4ba",
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
              # NOTE: here, the final induction record above has been converted to a stub because
              #       the induction_completion_date is before the start's end date
              started_on: Date.new(2025, 7, 22),
              finished_on: Date.new(2025, 7, 23),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 7, 22),
                  finished_on: Date.new(2025, 7, 23),
                  withdrawn_at: Time.zone.local(2025, 9, 4, 10, 1, 6),
                  withdrawal_reason: "other"
                )
              )
            )
          )
        )
      }
    end

    it "produces one ect_at_school_period with one training period" do
      expect(ecf2_teacher_history.ect_at_school_periods.count).to be(1)
      expect(ecf2_teacher_history.ect_at_school_periods[0].training_periods.count).to be(1)
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
              started_on: Date.new(2023, 6, 1),
              finished_on: Date.new(2025, 7, 31),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 6, 1),
                  finished_on: Date.new(2025, 7, 31)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 7, 31),
              finished_on: Date.new(2025, 9, 4),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 7, 31),
                  finished_on: Date.new(2025, 9, 4)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 9, 4),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 4),
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
