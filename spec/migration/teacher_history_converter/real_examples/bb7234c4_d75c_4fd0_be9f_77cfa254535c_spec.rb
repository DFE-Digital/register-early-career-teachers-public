describe "Real data check for user bb7234c4-d75c-4fd0-be9f-77cfa254535c (one ECT induction record, one mentor induction record)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "bb7234c4-d75c-4fd0-be9f-77cfa254535c",
      created_at: Time.zone.local(2022, 7, 12, 16, 59, 38),
      updated_at: Time.zone.local(2025, 10, 16, 12, 44, 59),
      ect: {
        participant_profile_id: "f1edf708-53c1-4c80-b785-12185149701d",
        created_at: Time.zone.local(2025, 10, 16, 12, 44, 59),
        updated_at: Time.zone.local(2025, 10, 16, 12, 44, 59),
        induction_start_date: :ignore,
        induction_completion_date: :ignore,
        pupil_premium_uplift: true,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 10, 16, 12, 44, 59),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          }
        ],
        induction_records: [
          {
            start_date: Date.new(2025, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2025,
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f9e8a8f6-ac8c-4efe-aafa-cb0d53e76910",
                name: "Delivery partner 1"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          }
        ]
      },
      mentor: {
        participant_profile_id: "003e0dc9-ae6b-45e9-a774-636bd80256cc",
        created_at: Time.zone.local(2022, 7, 12, 16, 59, 38),
        updated_at: Time.zone.local(2025, 10, 16, 12, 44, 59),
        mentor_completion_date: Date.new(2023, 2, 8),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "withdrawn",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "f9e8a8f6-ac8c-4efe-aafa-cb0d53e76910",
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
            created_at: Time.zone.local(2022, 7, 12, 16, 59, 38)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 12, 16, 59, 38)
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
              started_on: Date.new(2025, 9, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2025
                )
              )
            )
          ),
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
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
      {}
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
