describe "Real data check for user 4ab467c2-8450-4589-9134-6b2246a2548f" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "4ab467c2-8450-4589-9134-6b2246a2548f",
      created_at: Time.zone.local(2021, 9, 7, 8, 12, 53),
      updated_at: Time.zone.local(2025, 7, 3, 8, 34, 49),
      mentor: {
        participant_profile_id: "a10a57fc-a7dd-4329-868e-c1811704c7a0",
        created_at: Time.zone.local(2021, 9, 7, 8, 12, 53),
        updated_at: Time.zone.local(2025, 6, 23, 10, 24, 50),
        mentor_completion_date: Date.new(2021, 4, 19),
        mentor_completion_reason: "completed_during_early_roll_out",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            induction_record_id: "cabe2e13-a7e0-42e0-a590-0bef39c42d7a",
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2024, 9, 1),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "600dbeeb-01d6-4833-ab1f-a93e6b73bfd2",
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
          },
          {
            induction_record_id: "925502e4-4e77-4ace-9745-ae8853191d3e",
            start_date: Date.new(2024, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "600dbeeb-01d6-4833-ab1f-a93e6b73bfd2",
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
            created_at: Time.zone.local(2021, 9, 7, 8, 12, 53),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100002",
              name: "School 2"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2025, 1, 8, 12, 36, 32)
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
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2024, 8, 31),
              school: hash_including(
                urn: "100001",
                name: "School 1"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2024, 8, 31),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "600dbeeb-01d6-4833-ab1f-a93e6b73bfd2", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 9, 1),
              finished_on: nil,
              school: hash_including(
                urn: "100002",
                name: "School 2"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 9, 1),
                  finished_on: Date.new(2024, 9, 2),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "600dbeeb-01d6-4833-ab1f-a93e6b73bfd2", name: "Delivery partner 1" },
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

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2024, 8, 31),
              school: hash_including(
                urn: "100001",
                name: "School 1"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2024, 8, 31),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "600dbeeb-01d6-4833-ab1f-a93e6b73bfd2", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 9, 1),
              finished_on: nil,
              school: hash_including(
                urn: "100002",
                name: "School 2"
              ),
              training_periods: []
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
