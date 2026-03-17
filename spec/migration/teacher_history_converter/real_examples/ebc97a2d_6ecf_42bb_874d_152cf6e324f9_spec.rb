describe "Real data check for user ebc97a2d-6ecf-42bb-874d-152cf6e324f9 (setting deferral date and reason)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "ebc97a2d-6ecf-42bb-874d-152cf6e324f9",
      created_at: Time.zone.local(2023, 7, 3, 15, 25, 3),
      updated_at: Time.zone.local(2025, 7, 4, 12, 42, 58),
      ect: {
        participant_profile_id: "2e5f8f44-47ee-451e-a36c-0e0b410a4526",
        created_at: Time.zone.local(2023, 7, 3, 15, 25, 3),
        updated_at: Time.zone.local(2025, 7, 4, 12, 42, 58),
        induction_start_date: Date.new(2023, 9, 1),
        induction_completion_date: :ignore,
        pupil_premium_uplift: true,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 3, 15, 25, 3),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 7, 3, 15, 25, 3),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 8, 14, 20, 12, 22),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2025, 6, 2, 16, 6, 52),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          }
        ],
        induction_records: [
          {
            induction_record_id: "9546eaab-a195-4e69-a047-8950f96ec196",
            start_date: Date.new(2024, 1, 1),
            end_date: Date.new(2024, 6, 12),
            created_at: Time.zone.local(2023, 7, 3, 15, 25, 3),
            updated_at: Time.zone.local(2024, 8, 14, 20, 12, 22),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "be376d27-f667-418d-afad-22df24a8b509",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "febe6d76-175f-4d78-af7d-9be5a82f3f24",
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
          },
          {
            induction_record_id: "b86c8a99-21d8-4921-967a-379099c7cdaf",
            start_date: Date.new(2024, 6, 12),
            end_date: Date.new(2025, 6, 2),
            created_at: Time.zone.local(2024, 8, 14, 20, 12, 22),
            updated_at: Time.zone.local(2025, 6, 2, 16, 6, 52),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "0e4dc9f1-6d22-456b-af62-e2a995246390",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "febe6d76-175f-4d78-af7d-9be5a82f3f24",
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
          },
          {
            induction_record_id: "0d78c7c3-d69a-44bc-b950-c84defaf489d",
            start_date: Date.new(2025, 6, 2),
            end_date: :ignore,
            created_at: Time.zone.local(2025, 6, 2, 16, 6, 52),
            updated_at: Time.zone.local(2025, 6, 2, 16, 6, 52),
            training_programme: "full_induction_programme",
            cohort_year: 2023,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "active",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "0e4dc9f1-6d22-456b-af62-e2a995246390",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "febe6d76-175f-4d78-af7d-9be5a82f3f24",
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
              started_on: Date.new(2025, 6, 2),
              finished_on: nil,
              school: hash_including(name: "School 2"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 6, 2),
                  finished_on: Date.new(2025, 6, 3),
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  deferred_at: Time.zone.local(2025, 6, 2, 16, 6, 52),
                  deferral_reason: "other"
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
              started_on: Date.new(2023, 7, 3),
              finished_on: Date.new(2024, 6, 11),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 7, 3),
                  finished_on: Date.new(2024, 6, 11)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 6, 12),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 12),
                  finished_on: Date.new(2025, 6, 2)
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
