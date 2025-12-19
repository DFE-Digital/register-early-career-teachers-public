describe "One induction record (ongoing - no end date)" do
  subject(:actual_output) { ecf2_teacher_history.to_hash }

  let(:input) do
    {
      trn: '1234567',
      ect: {
        induction_records: [
          { start_date: Date.new(2024, 1, 2), end_date: :ignore }
        ]
      },
    }
  end

  let(:expected_output) do
    {
      teacher: hash_including(trn: '1234567')
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  it "produces the expected output" do
    expect(actual_output).to include(expected_output)
  end
end
