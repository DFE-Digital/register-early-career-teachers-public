describe "Real data check for user c82e38f1-920b-4ad0-98a3-5d69ee7f7b83" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "c82e38f1-920b-4ad0-98a3-5d69ee7f7b83",
      created_at: Time.zone.local(2022, 8, 11, 11, 27, 20),
      updated_at: Time.zone.local(2025, 6, 16, 0, 10, 57),
      mentor: {
        participant_profile_id: "410e7dfe-7561-4149-aad5-5bfdd099d04c",
        created_at: Time.zone.local(2022, 8, 11, 11, 27, 20),
        updated_at: Time.zone.local(2025, 6, 16, 0, 10, 57),
        mentor_completion_date: Date.new(2025, 6, 16),
        mentor_completion_reason: "started_not_completed",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2022, 6, 1),
            end_date: Date.new(2024, 1, 8),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "a8241698-1266-4ea8-b068-6bda4f508fd2",
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
          },
          {
            start_date: Date.new(2024, 1, 8),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "a8241698-1266-4ea8-b068-6bda4f508fd2",
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
            created_at: Time.zone.local(2022, 8, 11, 11, 27, 20)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 8, 11, 11, 27, 20)
          },
          {
            state: "withdrawn",
            reason: "switched-to-school-led",
            created_at: Time.zone.local(2024, 1, 8, 11, 40, 7)
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
              started_on: Date.new(2024, 1, 8),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 1, 8),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Education Development Trust"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022,
                  withdrawn_at: Time.zone.local(2024, 1, 8, 11, 40, 7),
                  withdrawal_reason: "switched-to-school-led"
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

    it "has no ect_at_school_periods" do
      expect(ecf2_teacher_history.ect_at_school_periods).to eql([])
    end

    it "has 1 mentor_at_school_periods" do
      expect(ecf2_teacher_history.mentor_at_school_periods.count).to be(1)
    end
  end

  context "when using the premium migrator", skip: "Implement premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: []
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
