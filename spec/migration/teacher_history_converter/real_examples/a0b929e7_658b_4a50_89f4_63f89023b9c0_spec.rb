describe "Real data check for user a0b929e7-658b-4a50-89f4-63f89023b9c0" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "a0b929e7-658b-4a50-89f4-63f89023b9c0",
      created_at: Time.zone.local(2022, 6, 30, 16, 26, 37),
      updated_at: Time.zone.local(2025, 1, 30, 16, 0, 17),
      mentor: {
        participant_profile_id: "b448c8c6-44ab-45a8-906c-597fa5c47853",
        created_at: Time.zone.local(2022, 7, 19, 15, 23, 53),
        updated_at: Time.zone.local(2025, 1, 30, 16, 0, 17),
        mentor_completion_date: Date.new(2023, 7, 31),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 11, 28),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "e41816f8-849e-40dd-a360-4a5bf5496fcd",
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
            start_date: Date.new(2023, 7, 31),
            end_date: Date.new(2023, 11, 28),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "e41816f8-849e-40dd-a360-4a5bf5496fcd",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "bc4101b2-55ea-4678-8143-342912205ec1",
              identifier: "ecf-replacement-april",
              name: "ECF Replacement April",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2023, 11, 28),
            end_date: Date.new(2023, 7, 31),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "a8b923cf-377f-4707-9014-6598f00d38d7",
                name: "Delivery partner 2"
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
            start_date: Date.new(2023, 11, 28),
            end_date: Date.new(2025, 1, 30),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "a8b923cf-377f-4707-9014-6598f00d38d7",
                name: "Delivery partner 2"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "bc4101b2-55ea-4678-8143-342912205ec1",
              identifier: "ecf-replacement-april",
              name: "ECF Replacement April",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2025, 1, 30),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
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
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "a8b923cf-377f-4707-9014-6598f00d38d7",
                name: "Delivery partner 2"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "bc4101b2-55ea-4678-8143-342912205ec1",
              identifier: "ecf-replacement-april",
              name: "ECF Replacement April",
              cohort_year: 2021
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 19, 15, 23, 53),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 19, 15, 23, 53),
            cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89"
          },
          {
            state: "withdrawn",
            reason: "mentor-no-longer-being-mentor",
            created_at: Time.zone.local(2025, 1, 30, 16, 0, 17),
            cpd_lead_provider_id: "dfad2a9c-527d-4d71-ae9a-492ab307e6c3"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2022, 7, 19, 15, 23, 53)
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
          ect_at_school_periods: [],
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2023, 7, 31),
              finished_on: Date.new(2023, 11, 28),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 7, 31),
                  finished_on: Date.new(2023, 11, 28),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31", name: "Ambition Institute" },
                  delivery_partner_info: { ecf1_id: "e41816f8-849e-40dd-a360-4a5bf5496fcd", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 1, 30),
              finished_on: nil,
              school: { urn: "100001", name: "School 1", school_type_name: nil },
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 1, 30),
                  finished_on: Date.new(2025, 1, 31),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408", name: "Best Practice Network" },
                  delivery_partner_info: { ecf1_id: "a8b923cf-377f-4707-9014-6598f00d38d7", name: "Delivery partner 2" },
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
          ect_at_school_periods: [],
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2023, 7, 31),
              finished_on: Date.new(2023, 11, 28),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 7, 31),
                  finished_on: Date.new(2023, 11, 28),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31", name: "Ambition Institute" },
                  delivery_partner_info: { ecf1_id: "e41816f8-849e-40dd-a360-4a5bf5496fcd", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 1, 30),
              finished_on: nil,
              school: { urn: "100001", name: "School 1", school_type_name: nil },
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 1, 30),
                  finished_on: Date.new(2025, 1, 31),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408", name: "Best Practice Network" },
                  delivery_partner_info: { ecf1_id: "a8b923cf-377f-4707-9014-6598f00d38d7", name: "Delivery partner 2" },
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
end
