describe "Real data check for user edb9fe1a-b074-4ba9-a116-83800d57cdc1" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "edb9fe1a-b074-4ba9-a116-83800d57cdc1",
      created_at: Time.zone.local(2025, 10, 17, 9, 43, 45),
      updated_at: Time.zone.local(2026, 3, 11, 0, 11, 4),
      ect: {
        participant_profile_id: "0d3fdfdd-6448-407e-ae03-96d373439462",
        created_at: Time.zone.local(2025, 10, 17, 9, 43, 45),
        updated_at: Time.zone.local(2026, 3, 11, 0, 11, 4),
        induction_start_date: Date.new(2025, 9, 1),
        induction_completion_date: :ignore,
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 10, 17, 9, 43, 45),
            cpd_lead_provider_id: :ignore
          }
        ],
        induction_records: [
          {
            induction_record_id: "0029da45-2b35-4aa1-b17b-ba224842d666",
            start_date: Date.new(2025, 6, 1),
            end_date: Date.new(2025, 10, 17),
            created_at: Time.zone.local(2025, 10, 17, 9, 43, 45),
            updated_at: Time.zone.local(2025, 10, 17, 12, 54, 10),
            training_programme: "core_induction_programme",
            cohort_year: 2025,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {
              ecf1_id: "c99bfcf6-1dc6-49fd-9a28-abe670720883",
              name: "Chafford Hundred Teaching School Hub (Harris Academy Chafford Hundred)"
            },
            training_provider_info: {},
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          },
          {
            induction_record_id: "16fe2dfd-58b4-48ca-b13f-edbdd7a8214c",
            start_date: Date.new(2025, 10, 17),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 10, 17, 12, 54, 10),
            updated_at: Time.zone.local(2025, 10, 17, 12, 54, 10),
            training_programme: "core_induction_programme",
            cohort_year: 2025,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "7ca53723-3d64-4f1f-a4bf-b46119c70759",
            appropriate_body: {
              ecf1_id: "c99bfcf6-1dc6-49fd-9a28-abe670720883",
              name: "Chafford Hundred Teaching School Hub (Harris Academy Chafford Hundred)"
            },
            training_provider_info: {},
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
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
              started_on: Date.new(2025, 10, 17),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 10, 17),
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

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: [
            hash_including(
              started_on: Date.new(2025, 6, 1),
              finished_on: nil,
              training_periods: [
                hash_including(
                  started_on: Date.new(2025, 6, 1),
                  finished_on: nil
                )
              ]
            )
          ]
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
