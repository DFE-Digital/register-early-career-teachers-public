describe "Real data check for user 924dd86e-416d-4d2e-aba3-6e72a8c3c8c5 (straightforward ECT example)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "924dd86e-416d-4d2e-aba3-6e72a8c3c8c5",
      created_at: Time.zone.local(2026, 1, 19, 22, 50, 43),
      updated_at: Time.zone.local(2026, 1, 19, 22, 50, 44),
      ect: {
        participant_profile_id: "b308530d-d9ec-4313-acf7-c2dae15b2bc6",
        created_at: Time.zone.local(2026, 1, 19, 22, 50, 43),
        updated_at: Time.zone.local(2026, 1, 19, 22, 50, 43),
        induction_start_date: Date.new(2026, 1, 13),
        induction_completion_date: nil,
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: nil,
        states: [
          {
            state: "active",
            reason: nil,
            created_at: Time.zone.local(2026, 1, 19, 22, 50, 43)
          }
        ],
        induction_records: [
          {
            start_date: Time.zone.local(2025, 6, 1, 1, 0, 0),
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
            mentor_profile_id: "e18870e3-45b8-4251-962d-3c00adf9c46b",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "82bfbad3-349f-44fb-bb60-621eab1b349b",
                name: "National Institute of Teaching"
              },
              delivery_partner: {
                ecf1_id: "1c888aea-a34e-4184-9452-bd2cb7b78747",
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
              started_on: Date.new(2025, 6, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 6, 1),
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
