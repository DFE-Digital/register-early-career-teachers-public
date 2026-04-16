describe "Real data check for user 8d629671-e99b-42ff-baa8-65262e936474" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "8d629671-e99b-42ff-baa8-65262e936474",
      created_at: Time.zone.local(2024, 9, 27, 9, 52, 37),
      updated_at: Time.zone.local(2026, 3, 10, 1, 59, 15),
      ect: {
        participant_profile_id: "b45b769f-8f11-46da-af8a-e63c4734d454",
        created_at: Time.zone.local(2024, 9, 27, 9, 52, 38),
        updated_at: Time.zone.local(2026, 3, 10, 1, 59, 15),
        induction_start_date: Date.new(2004, 9, 1),
        induction_completion_date: :ignore,
        pupil_premium_uplift: true,
        sparsity_uplift: true,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 9, 27, 9, 52, 38),
            cpd_lead_provider_id: "dfad2a9c-527d-4d71-ae9a-492ab307e6c3"
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2025, 7, 10, 10, 0, 13),
            cpd_lead_provider_id: "dfad2a9c-527d-4d71-ae9a-492ab307e6c3"
          }
        ],
        induction_records: [
          {
            induction_record_id: "fdaa8aae-d893-46e0-af1a-db20e3ce5714",
            start_date: Date.new(2024, 6, 1),
            end_date: Date.new(2024, 10, 16),
            created_at: Time.zone.local(2024, 9, 27, 9, 52, 38),
            updated_at: Time.zone.local(2024, 10, 16, 13, 38, 43),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "5bf76e6b-400b-4abe-9e93-17c4348498d8",
            appropriate_body: {
              ecf1_id: "f5018a20-0ea5-49f0-8b00-0a51fa478b5b",
              name: "Manor Teaching School Hub (Manor Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "65fb797c-b5b6-4b91-b989-ca3c944ad97d",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "b057ac5b-8917-41c8-aa63-cc4b94915f71",
            start_date: Date.new(2024, 10, 16),
            end_date: Date.new(2024, 10, 18),
            created_at: Time.zone.local(2024, 10, 16, 13, 38, 43),
            updated_at: Time.zone.local(2024, 10, 18, 10, 44, 40),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "5bf76e6b-400b-4abe-9e93-17c4348498d8",
            appropriate_body: {
              ecf1_id: "f5018a20-0ea5-49f0-8b00-0a51fa478b5b",
              name: "Manor Teaching School Hub (Manor Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "240103a4-d00c-45d6-b303-a4495b9ef6a3",
                name: "Delivery partner 2"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "26fa5999-d370-4967-b6b7-f382148888dd",
            start_date: Date.new(2024, 10, 18),
            end_date: Date.new(2025, 7, 10),
            created_at: Time.zone.local(2024, 10, 18, 10, 44, 40),
            updated_at: Time.zone.local(2025, 7, 10, 10, 0, 13),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "5bf76e6b-400b-4abe-9e93-17c4348498d8",
            appropriate_body: {
              ecf1_id: "f5018a20-0ea5-49f0-8b00-0a51fa478b5b",
              name: "Manor Teaching School Hub (Manor Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "65fb797c-b5b6-4b91-b989-ca3c944ad97d",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "a19017b9-c810-40fa-87f4-93541aef2368",
            start_date: Date.new(2025, 7, 10),
            end_date: Date.new(2025, 10, 15),
            created_at: Time.zone.local(2025, 7, 10, 10, 0, 13),
            updated_at: Time.zone.local(2025, 10, 15, 9, 3, 33),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "5bf76e6b-400b-4abe-9e93-17c4348498d8",
            appropriate_body: {
              ecf1_id: "f5018a20-0ea5-49f0-8b00-0a51fa478b5b",
              name: "Manor Teaching School Hub (Manor Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "65fb797c-b5b6-4b91-b989-ca3c944ad97d",
                name: "Delivery partner 1"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            induction_record_id: "9a49e372-066e-4f2f-9f16-fae528cb68ef",
            start_date: Date.new(2025, 10, 15),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 10, 15, 9, 3, 33),
            updated_at: Time.zone.local(2025, 10, 15, 9, 3, 33),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "5bf76e6b-400b-4abe-9e93-17c4348498d8",
            appropriate_body: {
              ecf1_id: "f5018a20-0ea5-49f0-8b00-0a51fa478b5b",
              name: "Manor Teaching School Hub (Manor Primary School)"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "a07f4f52-8064-452d-9e92-2282d0eb73d4",
                name: "Delivery partner 3"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
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
          ect_at_school_periods: array_including
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
              finished_on: Date.new(2026, 1, 4),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 10, 15),
                  finished_on: Date.new(2026, 1, 4),
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  withdrawn_at: Time.zone.local(2026, 1, 4, 0, 0, 0),
                  withdrawal_reason: "other"
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
