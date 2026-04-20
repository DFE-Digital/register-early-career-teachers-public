describe "Real data check for user 568580dd-c936-43b5-90f1-326a48050b41" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "568580dd-c936-43b5-90f1-326a48050b41",
      created_at: Time.zone.local(2022, 5, 24, 18, 38, 42),
      updated_at: Time.zone.local(2026, 2, 11, 15, 26, 33),
      mentor: {
        participant_profile_id: "0478b926-891d-4d50-b272-6d8bf7e3f0f3",
        created_at: Time.zone.local(2022, 5, 24, 18, 38, 42),
        updated_at: Time.zone.local(2026, 2, 11, 15, 26, 33),
        mentor_completion_date: Date.new(2025, 6, 16),
        mentor_completion_reason: "started_not_completed",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            induction_record_id: "ed414099-7ecf-4188-882c-d7de83843d65",
            start_date: Date.new(2022, 6, 1),
            end_date: Date.new(2023, 11, 23),
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "6ae866ae-7efd-46f1-a12d-26a81d1f350c",
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
            induction_record_id: "ca9463cb-ab1a-44e7-b1ef-446b948b85db",
            start_date: Date.new(2023, 6, 6),
            end_date: Date.new(2023, 11, 23),
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "6ae866ae-7efd-46f1-a12d-26a81d1f350c",
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
            induction_record_id: "2a467a07-d87f-46d7-87f8-14d18fc65eac",
            start_date: Date.new(2023, 10, 16),
            end_date: Date.new(2023, 11, 23),
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "6ae866ae-7efd-46f1-a12d-26a81d1f350c",
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
            induction_record_id: "0ab8f5f2-7c86-4914-90c0-0d0aaf278f71",
            start_date: Date.new(2023, 11, 1),
            end_date: Date.new(2023, 11, 23),
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
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "6ae866ae-7efd-46f1-a12d-26a81d1f350c",
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
            induction_record_id: "26f6b6fd-4efb-4723-b199-f7f01b177cc2",
            start_date: Date.new(2023, 11, 23),
            end_date: Date.new(2023, 6, 6),
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
                ecf1_id: "26d5c2ec-c7f1-4d57-9dac-40c31a5f512c",
                name: "Delivery partner 2"
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
            induction_record_id: "1b82dbab-7493-4f65-a317-216e962560f0",
            start_date: Date.new(2023, 11, 23),
            end_date: Date.new(2023, 10, 16),
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
                ecf1_id: "26d5c2ec-c7f1-4d57-9dac-40c31a5f512c",
                name: "Delivery partner 2"
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
            induction_record_id: "538d8cc8-3b1d-40bd-95a7-f3987a36b1cb",
            start_date: Date.new(2023, 11, 23),
            end_date: Date.new(2023, 11, 1),
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
                ecf1_id: "26d5c2ec-c7f1-4d57-9dac-40c31a5f512c",
                name: "Delivery partner 2"
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
            induction_record_id: "45f49c8d-22ac-4868-a564-fb033cc53220",
            start_date: Date.new(2023, 11, 23),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "26d5c2ec-c7f1-4d57-9dac-40c31a5f512c",
                name: "Delivery partner 2"
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
            created_at: Time.zone.local(2022, 5, 24, 18, 38, 42),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2023, 6, 6, 10, 56, 55),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 10, 16, 16, 56, 35),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2023, 11, 1, 16, 31, 32),
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
            created_at: Time.zone.local(2022, 5, 24, 18, 38, 42)
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
              started_on: Date.new(2023, 11, 1),
              finished_on: Date.new(2023, 11, 22),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 11, 1),
                  finished_on: Date.new(2023, 11, 22),
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  deferred_at: Time.zone.local(2023, 11, 1, 16, 31, 32),
                  deferral_reason: "other"
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 11, 23),
              # NOTE: patched date also used for school period
              finished_on: Date.new(2025, 6, 16),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 11, 23),
                  finished_on: Date.new(2025, 6, 16),
                  lead_provider_info: hash_including(name: "Teach First"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2")
                  # note, none of the states were supplied by TF, only UCL, so no
                  # deferral data here despite the source record's training_status
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
              started_on: Date.new(2022, 6, 1),
              # NOTE: patched date also used for school period
              finished_on: Date.new(2025, 6, 16),
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 6, 1),
                  finished_on: Date.new(2023, 11, 22),
                  lead_provider_info: hash_including(name: "UCL Institute of Education"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1")
                ),
                hash_including(
                  started_on: Date.new(2023, 11, 23),
                  finished_on: Date.new(2025, 6, 16),
                  lead_provider_info: hash_including(name: "Teach First"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2")
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
