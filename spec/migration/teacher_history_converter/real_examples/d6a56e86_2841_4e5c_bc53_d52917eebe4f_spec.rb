describe "Real data check for user d6a56e86-2841-4e5c-bc53-d52917eebe4f" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "d6a56e86-2841-4e5c-bc53-d52917eebe4f",
      created_at: Time.zone.local(2022, 6, 30, 13, 55, 34),
      updated_at: Time.zone.local(2025, 6, 17, 13, 3, 36),
      mentor: {
        participant_profile_id: "499bd79a-56a6-423d-99b4-1af0972f7a6c",
        created_at: Time.zone.local(2022, 6, 30, 13, 55, 34),
        updated_at: Time.zone.local(2025, 6, 17, 13, 3, 36),
        mentor_completion_date: Date.new(2025, 6, 16),
        mentor_completion_reason: "started_not_completed",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2022, 6, 1),
            end_date: Date.new(2022, 9, 6),
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
                ecf1_id: "d1e96e3d-94eb-4c6b-8cf0-ff6a6f529ad3",
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
            start_date: Date.new(2022, 9, 6),
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
                ecf1_id: "d1e96e3d-94eb-4c6b-8cf0-ff6a6f529ad3",
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
                ecf1_id: "d1e96e3d-94eb-4c6b-8cf0-ff6a6f529ad3",
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
            created_at: Time.zone.local(2022, 6, 30, 13, 55, 34),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "withdrawn",
            reason: "switched-to-school-led",
            created_at: Time.zone.local(2024, 1, 8, 15, 40, 39),
            cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2022, 6, 30, 13, 55, 34)
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }
  let(:ecf2_teacher_history) { converter.convert_to_ecf2! }

  context "choosing a migration strategy" do
    let(:migration_mode) { nil }

    it "chooses premium" do
      expect(converter.migration_mode).to be(:all_induction_records)
    end
  end
end
