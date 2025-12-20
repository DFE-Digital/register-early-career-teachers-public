describe "One induction record (ongoing - no end date)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1234567",
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          { start_date: Date.new(2024, 1, 2), end_date: :ignore }
        ]
      },
    }
  end

  let(:expected_output) do
    {
      teacher: hash_including(
        trn: "1234567",
        api_ect_training_record_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        ect_at_school_periods: [
          hash_including(started_on: Date.new(2024, 1, 2), finished_on: nil)
        ]
      ),
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  it "produces the expected output" do
    expect(actual_output).to include(expected_output)
  end
end
