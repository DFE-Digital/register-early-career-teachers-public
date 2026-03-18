describe "Real data check for user 4ab942af-3437-44a4-ba84-767ff8ba5b67" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "4ab942af-3437-44a4-ba84-767ff8ba5b67",
      created_at: Time.zone.local(2022, 2, 1, 10, 55, 1),
      updated_at: Time.zone.local(2025, 6, 24, 12, 9, 44),
      mentor: {
        participant_profile_id: "e941ad8d-0558-4faa-82fa-efe089b34c24",
        created_at: Time.zone.local(2022, 6, 22, 12, 1, 57),
        updated_at: Time.zone.local(2025, 6, 24, 12, 9, 44),
        mentor_completion_date: Date.new(2021, 4, 19),
        mentor_completion_reason: "completed_during_early_roll_out",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2022, 6, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "fd88f9d6-8677-4d4d-a8d2-b1cdb2c5a693",
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
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 6, 22, 12, 1, 57)
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
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 6, 1),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                # FIXME: once #2457 is merged and we set the TP to finish on the mentor_completion_date,
                #        this training period will become a stub
                hash_including(
                  started_on: Date.new(2022, 6, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  training_programme: "provider_led",
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

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 6, 1),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 6, 1),
                  finished_on: nil,
                  # FIXME: once #2457 is merged and we set the TP to finish on the mentor_completion_date,
                  #        this training period should vanish
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  training_programme: "provider_led",
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
end
