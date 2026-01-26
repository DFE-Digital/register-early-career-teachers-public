class SpecGenerator
  attr_reader :ecf1_teacher_history

  def initialize(ecf1_teacher_history)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def save!
    filename = "spec/migration/teacher_history_converter/real_examples/#{user_id.tr('-', '_')}_spec.rb"

    File.write(filename, spec)
  end

  def spec
    induction_records = ecf1_teacher_history.ect.induction_records
    induction_blocks = induction_records.map do |induction_record|
      <<~IR.chomp
        hash_including(
          started_on: Date.new(#{induction_record.start_date.year}, #{induction_record.start_date.month}, #{induction_record.start_date.day}),
          finished_on: #{induction_record.end_date ? "Date.new(#{induction_record.end_date.year}, #{induction_record.end_date.month}, #{induction_record.end_date.day})" : 'nil'},
          training_periods: array_including(
            hash_including(
              started_on: Date.new(#{induction_record.start_date.year}, #{induction_record.start_date.month}, #{induction_record.start_date.day}),
              finished_on: #{induction_record.end_date ? "Date.new(#{induction_record.end_date.year}, #{induction_record.end_date.month}, #{induction_record.end_date.day})" : 'nil'}
            )
          )
        )
      IR
    end

    input_source = SpecObjectFormatter.new(ecf1_teacher_history_hash, 0).formatted_object

    <<~SPEC
      describe "Real data check for user #{user_id}" do
        subject(:actual_output) { ecf2_teacher_history.to_h }

        let(:input) do
      #{input_source.indent(4)}
        end

        let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
        let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

        context "when using the economy migrator" do
          let(:migration_mode) { :latest_induction_records }

          let(:expected_output) do
            {
              teacher: hash_including(
                trn: "11111111",
                ect_at_school_periods: array_including(
      #{induction_blocks.join(",\n").indent(12)}
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
                trn: "11111111",
                ect_at_school_periods: array_including(
      #{induction_blocks.join(",\n").indent(12)}
                )
              )
            }
          end

          it "matches the expected output" do
            expect(actual_output).to include(expected_output)
          end
        end
      end
    SPEC
  end

  def ecf1_teacher_history_hash
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
    #     ]
    #   }
    # }
    {
      **ecf1_teacher_data,
      **ecf1_ect_data,
      **ecf1_mentor_data
    }
  end

private

  def user_id
    ecf1_teacher_history.user.user_id
  end

  def ecf1_teacher_data
    user = ecf1_teacher_history.user

    {
      trn: user.trn,
      full_name: user.full_name,
      user_id: user.user_id,
      created_at: user.created_at,
      updated_at: user.updated_at,
    }
  end

  def ecf1_ect_data
    ect = ecf1_teacher_history.ect

    return {} if ect.blank?

    {
      ect: {
        participant_profile_id: ect.participant_profile_id,
        created_at: ect.created_at,
        updated_at: ect.updated_at,
        induction_start_date: ect.induction_start_date,
        induction_completion_date: ect.induction_completion_date,
        pupil_premium_uplift: ect.pupil_premium_uplift,
        sparsity_uplift: ect.sparsity_uplift,
        payments_frozen_cohort_start_year: ect.payments_frozen_cohort_start_year,
        states: ecf1_ect_states,
        induction_records: ecf1_ect_induction_records
      }
    }
  end

  def ecf1_ect_induction_records
    ecf1_teacher_history.ect.induction_records.map do |ir|
      {
        start_date: ir.start_date,
        end_date: ir.end_date,
        training_programme: ir.training_programme,
        cohort_year: ir.cohort_year,
        school: ir.school.to_h,
        induction_status: ir.induction_status,
        training_status: ir.training_status,
        preferred_identity_email: ir.preferred_identity_email,
        mentor_profile_id: ir.mentor_profile_id,
        training_provider_info: ir.training_provider_info.then do |tpi|
          if ir.training_programme == "full_induction_programme"
            {
              lead_provider: tpi.lead_provider_info.to_h,
              delivery_partner: tpi.delivery_partner_info.to_h,
              cohort_year: tpi.cohort_year
            }
          else
            {}
          end
        end,
        schedule_info: ir.schedule_info.to_h
      }
    end
  end

  def ecf1_ect_states
    ecf1_teacher_history.ect.states.map do |s|
      { state: s.state, reason: s.reason, created_at: s.created_at }
    end
  end

  def ecf1_mentor_data
    mentor = ecf1_teacher_history.mentor

    return {} if mentor.blank?

    {
      mentor: {
        participant_profile_id: mentor.participant_profile_id,
        created_at: mentor.created_at,
        updated_at: mentor.updated_at,
        mentor_completion_date: mentor.mentor_completion_date,
        mentor_completion_reason: mentor.mentor_completion_reason,
        payments_frozen_cohort_start_year: mentor.payments_frozen_cohort_start_year,
        induction_records: ecf1_mentor_induction_records,
        states: ecf1_mentor_states,
      }
    }
  end

  def ecf1_mentor_states
    ecf1_teacher_history.mentor.states.map do |s|
      { state: s.state, reason: s.reason, created_at: s.created_at }
    end
  end

  def ecf1_mentor_induction_records
    ecf1_teacher_history.mentor.induction_records.map do |ir|
      {
        start_date: ir.start_date,
        end_date: ir.end_date,
        training_programme: ir.training_programme,
        cohort_year: ir.cohort_year,
        school: ir.school.to_h,
        induction_status: ir.induction_status,
        training_status: ir.training_status,
        preferred_identity_email: ir.preferred_identity_email,
        mentor_profile_id: ir.mentor_profile_id,
        training_provider_info: ir.training_provider_info.then do |tpi|
          if ir.training_programme == "full_induction_programme"
            {
              lead_provider: tpi.lead_provider_info.to_h,
              delivery_partner: tpi.delivery_partner_info.to_h,
              cohort_year: tpi.cohort_year
            }
          else
            {}
          end
        end,
        schedule_info: ir.schedule_info.to_h
      }
    end
  end
end
