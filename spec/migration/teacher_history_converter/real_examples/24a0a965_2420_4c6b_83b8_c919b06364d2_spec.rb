describe "Real data check for user 24a0a965-2420-4c6b-83b8-c919b06364d2" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "24a0a965-2420-4c6b-83b8-c919b06364d2",
      created_at: Time.zone.local(2021, 7, 13, 22, 13, 32),
      updated_at: Time.zone.local(2025, 7, 3, 2, 19, 33),
      mentor: {
        participant_profile_id: "01c8f984-b09b-49f0-8eac-b892a082889e",
        created_at: Time.zone.local(2022, 10, 10, 12, 24, 19),
        updated_at: Time.zone.local(2025, 7, 3, 2, 19, 33),
        mentor_completion_date: Date.new(2025, 6, 16),
        mentor_completion_reason: "started_not_completed",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            induction_record_id: "92305ff7-f71c-41ff-84ed-4c76078a60f7",
            start_date: Date.new(2022, 6, 1),
            end_date: Date.new(2023, 8, 21),
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
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
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
            induction_record_id: "660c6496-9e3d-494e-9815-4d03f2393548",
            start_date: Date.new(2023, 8, 21),
            end_date: Date.new(2024, 12, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
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
            induction_record_id: "19cf614a-52b5-4f04-8c02-76d2d3f27657",
            start_date: Date.new(2024, 12, 11),
            end_date: Date.new(2024, 12, 11),
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
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
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
            induction_record_id: "38c9909c-848b-4a38-a5a7-5e2976408573",
            start_date: Date.new(2024, 12, 11),
            end_date: Date.new(2024, 12, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
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
            induction_record_id: "7062b07f-fe0f-4459-8b11-e441ce4464b2",
            start_date: Date.new(2024, 12, 11),
            end_date: Date.new(2024, 12, 11),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
                name: "Delivery partner 1"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "686ffc41-3d41-437f-9cbd-4ddb1001ef79",
              identifier: "ecf-extended-september",
              name: "ECF Extended September",
              cohort_year: 2022
            }
          },
          {
            induction_record_id: "245ca9c4-a92d-471b-92f5-5d116f4dd2c7",
            start_date: Date.new(2024, 12, 11),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "ebbf7c44-e906-4b05-a9b3-0c44a5193af9",
                name: "Delivery partner 1"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "686ffc41-3d41-437f-9cbd-4ddb1001ef79",
              identifier: "ecf-extended-september",
              name: "ECF Extended September",
              cohort_year: 2022
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 10, 10, 12, 24, 19),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 10, 10, 12, 24, 19),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "withdrawn",
            reason: "mentor-no-longer-being-mentor",
            created_at: Time.zone.local(2023, 8, 21, 9, 40, 18),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 12, 11, 11, 14, 12),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2024, 12, 11, 11, 15, 50),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 12, 11, 11, 15, 54),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2022, 10, 10, 12, 24, 19)
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

          )
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
