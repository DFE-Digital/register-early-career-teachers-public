describe ECF1TeacherHistory::ECT do
  describe ".from_hash" do
    subject { ECF1TeacherHistory::ECT.from_hash(input) }

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
end
