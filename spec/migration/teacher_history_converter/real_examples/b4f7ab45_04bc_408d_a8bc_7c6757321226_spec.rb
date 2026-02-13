describe "Real data check for user b4f7ab45-04bc-408d-a8bc-7c6757321226" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "b4f7ab45-04bc-408d-a8bc-7c6757321226",
      created_at: Time.zone.local(2021, 6, 29, 9, 19, 44),
      updated_at: Time.zone.local(2024, 7, 5, 8, 56, 20),
      mentor: {
        participant_profile_id: "1fe82535-7981-4048-8f12-c95e3436edea",
        created_at: Time.zone.local(2021, 6, 29, 9, 19, 44),
        updated_at: Time.zone.local(2024, 6, 13, 15, 46, 7),
        mentor_completion_date: Date.new(2023, 3, 23),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2021, 9, 1),
            training_programme: "core_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
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
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2022, 9, 7),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "39d9e9e4-13c1-4833-8318-a46c4d91ea7c",
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
            start_date: Date.new(2022, 9, 7),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "39d9e9e4-13c1-4833-8318-a46c4d91ea7c",
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
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 6, 29, 9, 19, 44)
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
            # this record has been bumped from 0 to 1 days long
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2021, 9, 2),
              training_periods: [],
              school: hash_including(urn: "100001")
            ),
            hash_including(
              started_on: Date.new(2022, 9, 7),
              finished_on: nil,
              school: hash_including(urn: "100002"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 7),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Best Practice Network"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1")
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
          trn: "1111111"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
