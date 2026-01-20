describe ECF1TeacherHistory::Mentor do
  describe ".from_hash" do
    subject do
      ECF1TeacherHistory::Mentor.from_hash(input)
    end

    let(:input) do
      {
        states: [
          { state: "State 1", reason: "Reason 1", created_at: 3.weeks.ago },
          { state: "State 2", reason: "Reason 2", created_at: 4.weeks.ago }
        ]
      }
    end

    it "converts the array of states into ECF1TeacherHistory::ProfileState objects" do
      expect(subject.states).to all(be_a(ECF1TeacherHistory::ProfileState))
      expect(subject.states.count).to be(2)
    end

    it "correctly sets the values" do
      input[:states].each_with_index do |original_hash, i|
        obj = subject.states[i]

        original_hash.each { |k, v| expect(obj.send(k)).to eql(v) }
      end
    end
  end

  describe "#induction_records" do
    let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records:) }

    before do
      allow(mentor).to receive(:all_induction_records).and_return(induction_records)
    end

    {
      # No changes
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 }] => 1,
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 }] => 1,

      # Only lead provider changes
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aab", urn: "111_111", cohort_year: 2023 }] => 2,
      # Only URN changes
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aaa", urn: "111_112", cohort_year: 2023 }] => 2,
      # Only cohort changes
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aaa", urn: "111_111", cohort_year: 2024 }] => 2,

      # Multiple changes
      [{ ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aab", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aac", urn: "111_111", cohort_year: 2023 }] => 3,

      [{ ecf1_id: "111aax", urn: "111_111", cohort_year: 2022 },
       { ecf1_id: "111aay", urn: "111_111", cohort_year: 2022 },
       { ecf1_id: "111aaz", urn: "111_111", cohort_year: 2022 },

       { ecf1_id: "111aaa", urn: "111_112", cohort_year: 2022 },
       { ecf1_id: "111aaa", urn: "111_113", cohort_year: 2022 },
       { ecf1_id: "111aaa", urn: "111_114", cohort_year: 2022 },

       { ecf1_id: "111aaa", urn: "111_111", cohort_year: 2023 },
       { ecf1_id: "111aaa", urn: "111_111", cohort_year: 2024 },
       { ecf1_id: "111aaa", urn: "111_111", cohort_year: 2025 }] => 9
    }.each do |rows, expected_combinations|
      context "when there are #{expected_combinations} combinations in #{rows.count} records" do
        let(:induction_records) do
          rows.map do |row|
            ECF1TeacherHistory::InductionRecord.from_hash(
              {
                school: { urn: row.fetch(:urn), name: "Test" },
                training_provider_info: {
                  lead_provider: { ecf1_id: row.fetch(:ecf1_id), name: "Test" },
                  delivery_partner: { ecf1_id: "111bbb", name: "Test" },
                  cohort_year: 0
                },
                cohort_year: row.fetch(:cohort_year)
              }
            )
          end
        end

        it "returns the right count" do
          expect(mentor.induction_records(migration_mode: :latest_induction_records).count).to be(expected_combinations)
        end
      end
    end
  end
end
