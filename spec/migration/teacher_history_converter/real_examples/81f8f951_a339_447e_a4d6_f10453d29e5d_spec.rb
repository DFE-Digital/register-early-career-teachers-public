describe "Real data check for user 81f8f951-a339-447e-a4d6-f10453d29e5d" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "81f8f951-a339-447e-a4d6-f10453d29e5d",
      created_at: Time.zone.local(2023, 2, 26, 20, 22, 8),
      updated_at: Time.zone.local(2025, 6, 16, 22, 18, 9),
      mentor: {
        participant_profile_id: "160bdffd-ff0d-42ec-9270-febd9f594155",
        created_at: Time.zone.local(2023, 9, 6, 15, 45, 0),
        updated_at: Time.zone.local(2025, 6, 16, 22, 18, 9),
        mentor_completion_date: Date.new(2025, 6, 16),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2023, 6, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2023,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "6e21f4bd-0fcc-4a90-8c14-d77d06074578",
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
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 6, 15, 45, 0)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 6, 15, 45, 0)
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
            hash_including(
              started_on: Date.new(2023, 6, 1),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 6, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2023
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
        teacher: hash_including(trn: "1111111")
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
