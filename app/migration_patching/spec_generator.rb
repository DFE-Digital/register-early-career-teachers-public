class SpecGenerator
  attr_reader :teacher_history

  def initialize(teacher_history)
    @teacher_history = teacher_history
  end

  def save!
    filename = "spec/migration_patching/real_examples/teacher_#{teacher_id}_spec.rb"

    File.write(filename, spec)
  end

  def school_history(school_period)
    <<~PERIOD.chomp
      hash_including(
        started_on: Date.parse(#{school_period[:started_on]}),
        finished_on: #{school_period[:finished_on].present? ? "Date.parse(#{school_period[:finished_on]})" : 'nil'},
        training_periods: array_including(
          #{training_history_at_school(school_period[:training_periods])}
        ),
        mentorship_periods: array_including(
          #{mentorship_history_at_school(school_period[:mentorship_periods])}
        )
      ),
    PERIOD
  end

  def training_history_at_school(training_periods)
    training_periods.map do |training_period|
      <<~PERIOD.chomp
          hash_including(
            started_on: Date.parse("#{training_period[:started_on]}"),
            finished_on: #{training_period[:finished_on].present? ? "Date.parse(\"#{training_period[:finished_on]}\")" : 'nil'},
            training_programme: #{training_period[:training_programme]},
            school_partnership: hash_including(
            )
          ),
        ),
      PERIOD
    end
  end

  def mentorship_history_at_school(mentorship_periods)
    mentorship_periods.map do |mentorship_period|
    end
  end

  def spec
    ect_periods = teacher_history.ect_at_school_periods.map do |school_period|
      school_history(school_period)
    end

    mentor_periods = teacher_history.mentor_at_school_periods.map do |school_period|
      school_history(school_period)
    end

    # input_source = SpecObjectFormatter.new(teacher_history_hash, 0).formatted_object

    <<~SPEC
      describe "Real data check for teacher #{teacher_id}" do
        subject(:actual_output) { "insert-your-converter-call-here-and-result-as-a-hash" }

        let(:input) do
      {input_source.indent(4)}
        end

        let(:teacher_history) { TeacherHistory.new(teacher_hash: input) }

        let(:expected_output) do
          {
            teacher: hash_including(
              trn: "1111111",
              ect_at_school_periods: array_including(
                #{ect_periods}
              ),
              mentor_at_school_periods: array_including(
                #{mentor_periods}
              )
            )
          }
        end

        it "matches the expected output" do
          expect(actual_output).to include(expected_output)
        end
      end
    SPEC
  end

  def teacher_history_hash
    # {
    #   trn: "1234567",
    #   ect: {
    #     participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
    #     created_at: 1.year.ago,
    #     updated_at: 6.months.ago,
    #     induction_start_date: 3.years.ago.to_date,
    #     induction_completion_date: 3.weeks.ago.to_date,
    #     pupil_premium_uplift: true,
    #     sparsity_uplift: false,
    #     payments_frozen_cohort_start_year: 2023,
    #     states: [
    #       { state: "active", reason: nil, created_at: 1.year.ago },
    #       { state: "withdrawn", reason: "mentor-no-longer-being-mentor", created_at: 6.months.ago }
    #     ],
    #     induction_records: [
    #       {
    #         start_date: Date.new(2024, 1, 2),
    #         end_date: :ignore,
    #         training_programme: "full_induction_programme",
    #         cohort_year:,
    #         school:,
    #         training_provider_info: {
    #           lead_provider: { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" },
    #           delivery_partner: { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" },
    #           cohort_year:
    #         }
    #       }
    #     ],
    #     mentor_at_school_periods: [
    #       {
    #         started_on: Date.new(2024, 1, 2),
    #         finished_on: :ignore,
    #         created_at: Time.zone.local(2024, 1, 2, 0, 0, 3),
    #         updated_at: Time.zone.local(2025, 7, 22, 15, 3, 3),
    #         school: {
    #           urn: "100002",
    #           name: "School 2"
    #         },
    #         teacher: {
    #           api_mentor_training_record_id: "dddddd-2222-6666-aaaa-cccccccccccc" },
    #           trn: "123112"
    #         }
    #       }
    #     ]
    #   },
    #   mentor: {
    #     participant_profile_id: "11111111-2222-3333-aaaa-cccccccccccc",
    #     created_at: 6.months.ago,
    #     updated_at: 3.months.ago,
    #     mentor_completion_date: Date.new(2025, 1, 2),
    #     mentor_completion_reason: "completed_declaration_received",
    #     payments_frozen_cohort_start_year: 2024,
    #     states: [
    #       { state: "active", reason: nil, created_at: 3.months.ago },
    #       { state: "deferred", reason: "long-term-sickness", created_at: 2.months.ago }
    #     ],
    #     induction_records: [
    #       {
    #         start_date: Date.new(2025, 3, 3),
    #         end_date: Date.new(2025, 4, 4),
    #         training_programme: "full_induction_programme",
    #         cohort_year: mentor_cohort_year,
    #         school: school_a,
    #         training_provider_info: {
    #           lead_provider: { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" },
    #           delivery_partner: { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" },
    #           cohort_year: mentor_cohort_year
    #         },
    #         training_status: "active",
    #         induction_status: "active",
    #         preferred_identity_email: "test3@account.com",
    #         schedule_info: {
    #           schedule_id: "77777777-4444-5555-eeee-bbbbbbbbbbbb",
    #           identifier: "ecf-replacement-april",
    #           name: "ECF Replacement April",
    #           cohort_year: mentor_cohort_year
    #         }
    #       },
    #     ],
    #     school_mentors: [
    #       {
    #         school: {
    #           urn: "100002",
    #           name: "School 2"
    #         },
    #         preferred_identity_email: "something@example.com",
    #         created_at: Time.zone.local(2023, 7, 10, 11, 57, 7)
    #       }
    #     ]
    #   }
    # }
    teacher_history.to_h
  end

  delegate :teacher_id, to: :teacher_history
end
