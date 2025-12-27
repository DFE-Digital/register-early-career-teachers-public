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
    <<~SPEC
      describe "Real data check for user #{user_id}" do
        subject(:actual_output) { ecf2_teacher_history.to_h }

        let(:input) do
          #{SpecObjectFormatter.new(ecf1_teacher_history_hash, 4).formatted_object}
        end

        let(:expected_output) do
          {}
        end

        let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
        let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

        it "produces the expected output", skip: "set the expected_output" do
          expect(actual_output).to include(expected_output)
        end
      end
    SPEC
  end

  def ecf1_teacher_history_hash
    # {
    #   trn: "1234567",
    #   ect: {
    #     participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
    #     induction_records: [
    #       {
    #         start_date: Date.new(2024, 1, 2),
    #         end_date: :ignore,
    #         training_programme: "full_induction_programme",
    #         cohort_year:,
    #         school:,
    #         training_provider_info: {
    #           lead_provider_info: lead_provider_a,
    #           delivery_partner_info: delivery_partner_a,
    #           cohort_year:
    #         }
    #       }
    #     ]
    #   },
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
    return {} if ecf1_teacher_history.ect.blank?

    {
      ect: {
        participant_profile_id: ecf1_teacher_history.ect.participant_profile_id,
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
        end
      }
    end
  end

  def ecf1_mentor_data
    # TODO: write this

    {}
  end

  def ecf1_mentor_induction_records
    # TODO: write this

    []
  end
end
