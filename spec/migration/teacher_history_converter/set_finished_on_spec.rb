class FakeConverter
  include TeacherHistoryConverter::SetFinishedOn
end

describe TeacherHistoryConverter::SetFinishedOn do
  let(:fake_converter) { FakeConverter.new }

  let(:start_date) { Date.new(2026, 1, 1) }
  let(:first_february_2026) { Date.new(2026, 2, 1) }
  let(:second_february_2026) { Date.new(2026, 2, 2) }
  let(:third_february_2026) { Date.new(2026, 2, 3) }

  let(:end_date) { second_february_2026 }
  let(:deferral_date) { second_february_2026 }
  let(:withdrawal_date) { second_february_2026 }

  describe "#ect_finished_on" do
    subject { fake_converter.ect_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, induction_completion_date:) }

    let(:induction_completion_date) { second_february_2026 }

    context "when the induction period's end date is earliest" do
      let(:end_date) { first_february_2026 }

      it "sets the finished on to the induction period end date" do
        expect(subject).to eql(end_date)
      end
    end

    context "when the deferral_date is earliest" do
      let(:deferral_date) { first_february_2026 }

      it "sets the finished on to the deferral_date" do
        expect(subject).to eql(deferral_date)
      end
    end

    context "when the withdrawal_date is earliest" do
      let(:withdrawal_date) { first_february_2026 }

      it "sets the finished on to the withdrawal_date" do
        expect(subject).to eql(withdrawal_date)
      end
    end

    context "when the induction_completion_date is earliest" do
      let(:induction_completion_date) { first_february_2026 }

      it "sets the finished on to the induction_completion_date" do
        expect(subject).to eql(induction_completion_date)
      end
    end

    context "when the new finished_on date is before the induction period's start_date" do
      let(:end_date) { first_february_2026 }
      let(:start_date) { first_february_2026 + 5.days }

      it "sets the finished_on to the day after the start date" do
        expect(subject).to eql(start_date + 1.day)
      end
    end

    context "when the new finished_on date is the same as the induction period's start_date" do
      let(:end_date) { start_date }

      it "sets the finished_on to the day after the start date" do
        expect(subject).to eql(start_date + 1.day)
      end
    end

    context "when the dates are all nil" do
      subject { fake_converter.ect_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, induction_completion_date:) }

      let(:end_date) { nil }
      let(:deferral_date) { nil }
      let(:withdrawal_date) { nil }
      let(:induction_completion_date) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#mentor_finished_on" do
    subject { fake_converter.mentor_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, mentor_completion_date:) }

    let(:mentor_completion_date) { second_february_2026 }

    context "when the induction period's end date is earliest" do
      let(:end_date) { first_february_2026 }

      it "sets the finished on to the induction period end date" do
        expect(subject).to eql(end_date)
      end
    end

    context "when the deferral_date is earliest" do
      let(:deferral_date) { first_february_2026 }

      it "sets the finished on to the deferral_date" do
        expect(subject).to eql(deferral_date)
      end
    end

    context "when the withdrawal_date is earliest" do
      let(:withdrawal_date) { first_february_2026 }

      it "sets the finished on to the withdrawal_date" do
        expect(subject).to eql(withdrawal_date)
      end
    end

    context "when the mentor_completion_date is earliest" do
      let(:mentor_completion_date) { first_february_2026 }

      it "sets the finished on to the mentor_completion_date" do
        expect(subject).to eql(mentor_completion_date)
      end
    end

    context "when the new finished_on date is before the induction period's start_date" do
      let(:end_date) { first_february_2026 }
      let(:start_date) { first_february_2026 + 5.days }

      it "sets the finished_on to the day after the start date" do
        expect(subject).to eql(start_date + 1.day)
      end
    end

    context "when the new finished_on date is the same as the induction period's start_date" do
      let(:end_date) { start_date }

      it "sets the finished_on to the day after the start date" do
        expect(subject).to eql(start_date + 1.day)
      end
    end

    context "when the dates are all nil" do
      subject { fake_converter.mentor_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, mentor_completion_date:) }

      let(:end_date) { nil }
      let(:deferral_date) { nil }
      let(:withdrawal_date) { nil }
      let(:mentor_completion_date) { nil }

      it { is_expected.to be_nil }
    end
  end
end
