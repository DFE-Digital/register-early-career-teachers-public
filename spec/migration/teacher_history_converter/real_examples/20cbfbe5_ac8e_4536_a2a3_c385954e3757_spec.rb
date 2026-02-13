describe "Real data check for user 20cbfbe5-ac8e-4536-a2a3-c385954e3757" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "20cbfbe5-ac8e-4536-a2a3-c385954e3757",
      created_at: Time.zone.local(2024, 12, 18, 16, 0, 27),
      updated_at: Time.zone.local(2025, 1, 13, 7, 9, 28),
      ect: {
        participant_profile_id: "8e877dd4-764d-47f1-a099-260b7c01b23d",
        created_at: Time.zone.local(2024, 12, 18, 16, 0, 27),
        updated_at: Time.zone.local(2025, 1, 13, 7, 9, 28),
        induction_start_date: Date.new(2025, 1, 6),
        induction_completion_date: :ignore,
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 12, 18, 16, 0, 27)
          }
        ],
        induction_records: [
          {
            start_date: Date.new(2024, 6, 1),
            end_date: :ignore,
            training_programme: "core_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "a31bcd78-12c3-48f9-8ca1-2e18baeb569c",
            training_provider_info: {},
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
            hash_including(
              started_on: Date.new(2024, 6, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 1),
                  finished_on: nil,
                  training_programme: "school_led",
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
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 1),
                  finished_on: nil,
                  training_programme: "school_led",
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
end
