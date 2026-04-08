describe "Real data check for user ee88063b-f160-47bc-b4fa-859ef63c9b44" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "ee88063b-f160-47bc-b4fa-859ef63c9b44",
      created_at: Time.zone.local(2025, 7, 22, 13, 20, 3),
      updated_at: Time.zone.local(2026, 3, 12, 18, 13, 28),
      mentor: {
        participant_profile_id: "8b4863c1-274f-452e-a087-3d262e2fbc64",
        created_at: Time.zone.local(2025, 7, 25, 10, 37, 37),
        updated_at: Time.zone.local(2026, 3, 12, 18, 13, 28),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2025, 6, 1),
            end_date: Date.new(2025, 11, 5),
            training_programme: "full_induction_programme",
            cohort_year: 2025,
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ad725c3b-822d-4902-b48e-70aef11d0663",
                name: "Delivery partner 1"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          },
          {
            start_date: Date.new(2025, 11, 5),
            end_date: Date.new(2025, 11, 6),
            training_programme: "full_induction_programme",
            cohort_year: 2025,
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "ad725c3b-822d-4902-b48e-70aef11d0663",
                name: "Delivery partner 1"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          },
          {
            start_date: Date.new(2025, 11, 6),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2025,
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
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "28092c96-da70-4529-b843-b1f56973e0a4",
                name: "Delivery partner 2"
              },
              cohort_year: 2025
            },
            schedule_info: {
              schedule_id: "34508584-78cb-4e41-80ba-fcbec57da03f",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2025
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2025, 7, 25, 10, 37, 37),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2025, 11, 5, 10, 45, 0),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2025, 7, 25, 10, 37, 38)
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:).convert_to_ecf2! }

  # context "when using the economy migrator" do
  #   let(:migration_mode) { :latest_induction_records }
  #
  #   let(:expected_output) do
  #     {
  #       teacher: hash_including(
  #         trn: "1111111",
  #         ect_at_school_periods: array_including(
  #
  #         )
  #       )
  #     }
  #   end
  #
  #   it "matches the expected output" do
  #     expect(actual_output).to include(expected_output)
  #   end
  # end

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
      binding.debugger
      expect(actual_output).to include(expected_output)
    end
  end
end
