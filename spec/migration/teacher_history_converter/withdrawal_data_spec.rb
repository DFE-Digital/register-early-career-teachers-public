describe TeacherHistoryConverter::WithdrawalData do
  subject { TeacherHistoryConverter::WithdrawalData.new(training_status:, states:).withdrawal_data }

  let(:active_now) { ECF1TeacherHistory::ProfileState.new(state: "active", created_at: 1.minute.ago.round, reason: nil) }
  let(:withdrawn_one_year_ago) { ECF1TeacherHistory::ProfileState.new(state: "withdrawn", created_at: 1.year.ago.round, reason: "left_teaching_profession") }
  let(:active_two_years_ago) { ECF1TeacherHistory::ProfileState.new(state: "active", created_at: 2.years.ago.round, reason: nil) }
  let(:withdrawn_three_years_ago) { ECF1TeacherHistory::ProfileState.new(state: "withdrawn", created_at: 3.years.ago.round, reason: "other") }
  let(:active_four_years_ago) { ECF1TeacherHistory::ProfileState.new(state: "active", created_at: 4.years.ago.round, reason: nil) }
  let(:states) { [] }


  context "when training status isn't 'withdrawn'" do
    let(:training_status) { "active" }

    it "returns an empty hash" do
      expect(subject).to eql({})
    end
  end

  context "when training status is 'withdrawn'" do
    let(:training_status) { "withdrawn" }

    context "when there is a withdrawn state" do
      let(:states) { [active_four_years_ago, withdrawn_three_years_ago, active_two_years_ago, withdrawn_one_year_ago, active_now] }

      it "returns the most recent withdrawn state" do
        expect(subject).to eql({ withdrawal_reason: "left_teaching_profession", withdrawn_at: 1.year.ago.round })
      end
    end

    context "when there is no withdrawn state" do
      let(:states) { [active_four_years_ago, active_two_years_ago, active_now] }

      it "returns the most recent withdrawn state" do
        expect(subject).to eql({})
      end
    end
  end
end
