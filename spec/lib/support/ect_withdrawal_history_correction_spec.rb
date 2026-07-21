RSpec.describe Support::ECTWithdrawalHistoryCorrection do
  subject(:correct_withdrawal_history) do
    described_class.new(
      original_training_period:,
      erroneous_withdrawn_training_period:,
      corrected_end_date:,
      author:
    ).correct!
  end

  let(:author) { Events::SystemAuthor.new }

  let(:ect_started_on) { Date.new(2023, 9, 11) }
  let(:original_finished_on) { Date.new(2023, 11, 23) }
  let(:corrected_end_date) { Date.new(2023, 11, 10) }

  let(:erroneous_started_on) { Date.new(2025, 10, 7) }
  let(:erroneous_finished_on) { Date.new(2025, 11, 6) }
  let(:withdrawn_at) { Time.zone.parse("2025-11-06T12:20:55Z") }

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      started_on: ect_started_on,
      finished_on: nil
    )
  end

  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      school: ect_at_school_period.school,
      started_on: ect_started_on,
      finished_on: nil
    )
  end

  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      mentee: ect_at_school_period,
      mentor: mentor_at_school_period,
      started_on: ect_started_on,
      finished_on: nil
    )
  end

  let!(:original_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on: ect_started_on,
      finished_on: original_finished_on,
      withdrawn_at: nil,
      withdrawal_reason: nil
    )
  end

  let!(:erroneous_withdrawn_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on: erroneous_started_on,
      finished_on: erroneous_finished_on,
      withdrawn_at:,
      withdrawal_reason: "other"
    )
  end

  describe "#correct!" do
    it "moves the withdrawal details onto the original training period" do
      correct_withdrawal_history

      expect(original_training_period.reload).to have_attributes(
        withdrawn_at:,
        withdrawal_reason: "other"
      )
    end

    it "changes the original training period end date" do
      correct_withdrawal_history

      expect(original_training_period.reload.finished_on)
        .to eq(corrected_end_date)
    end

    it "removes the erroneous withdrawn training period" do
      expect { correct_withdrawal_history }
        .to change {
          TrainingPeriod.exists?(
            erroneous_withdrawn_training_period.id
          )
        }
        .from(true)
        .to(false)
    end

    it "finishes the ECT-at-school period" do
      correct_withdrawal_history

      expect(ect_at_school_period.reload.finished_on)
        .to eq(corrected_end_date)
    end

    it "finishes the linked mentorship period" do
      correct_withdrawal_history

      expect(mentorship_period.reload.finished_on)
        .to eq(corrected_end_date)
    end

    it "does not record events" do
      expect { correct_withdrawal_history }
        .not_to change(Event, :count)
    end

    context "when the original and erroneous periods are the same" do
      subject(:correct_withdrawal_history) do
        described_class.new(
          original_training_period:,
          erroneous_withdrawn_training_period:
            original_training_period,
          corrected_end_date:,
          author:
        ).correct!
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Original and erroneous training periods must be different"
          )
      end
    end

    context "when the training periods belong to different ECT-at-school periods" do
      let(:other_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          started_on: erroneous_started_on,
          finished_on: nil
        )
      end

      let(:erroneous_withdrawn_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          ect_at_school_period: other_ect_at_school_period,
          started_on: erroneous_started_on,
          finished_on: erroneous_finished_on,
          withdrawn_at:,
          withdrawal_reason: "other"
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training periods do not belong to the same ECT-at-school period"
          )
      end
    end

    context "when the ECT-at-school period is already finished" do
      before do
        ect_at_school_period.update_columns(
          finished_on: corrected_end_date
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "ECT-at-school period is already finished"
          )
      end
    end

    context "when the corrected end date is before the ECT-at-school period starts" do
      let(:corrected_end_date) { ect_started_on - 1.day }

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Corrected end date is before the ECT-at-school period start date"
          )
      end
    end

    context "when the original training period starts after the corrected end date" do
      before do
        original_training_period.update!(
          started_on: corrected_end_date + 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Original training period starts after the corrected end date"
          )
      end
    end

    context "when the original training period finishes before the corrected end date" do
      before do
        original_training_period.update!(
          finished_on: corrected_end_date - 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Original training period finishes before the corrected end date"
          )
      end
    end

    context "when the erroneous training period starts before the corrected end date" do
      before do
        erroneous_withdrawn_training_period.update_columns(
          started_on: corrected_end_date - 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Erroneous training period starts before the corrected end date"
          )
      end
    end

    context "when the original training period already has withdrawal details" do
      before do
        original_training_period.update!(
          withdrawn_at: Time.zone.parse("2024-01-01T12:00:00Z"),
          withdrawal_reason: "other"
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Original training period already has withdrawal details"
          )
      end
    end

    context "when the erroneous period has no withdrawal timestamp" do
      before do
        erroneous_withdrawn_training_period.update_columns(
          withdrawn_at: nil
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Erroneous training period has incomplete withdrawal details"
          )
      end
    end

    context "when the erroneous period has no withdrawal reason" do
      before do
        erroneous_withdrawn_training_period.update_columns(
          withdrawal_reason: nil
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Erroneous training period has incomplete withdrawal details"
          )
      end
    end

    context "when the original training period has declarations" do
      before do
        FactoryBot.create(
          :declaration,
          :eligible,
          training_period: original_training_period
        )
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Original training period has declarations"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when the erroneous training period has declarations" do
      before do
        FactoryBot.create(
          :declaration,
          :eligible,
          training_period: erroneous_withdrawn_training_period
        )
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Erroneous training period has declarations"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when the erroneous training period has events" do
      before do
        allow(erroneous_withdrawn_training_period.events)
          .to receive(:exists?)
          .and_return(true)
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            described_class::InvalidCorrection,
            "Erroneous training period has events"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when finishing the ECT-at-school period fails" do
      before do
        allow(ECTAtSchoolPeriods::Finish)
          .to receive(:new)
          .and_raise(StandardError, "finish failed")
      end

      it "rolls back the withdrawal changes" do
        expect { correct_withdrawal_history }
          .to raise_error(
            StandardError,
            "finish failed"
          )

        expect_records_to_remain_unchanged
      end
    end
  end

  def expect_records_to_remain_unchanged
    expect(original_training_period.reload).to have_attributes(
      finished_on: original_finished_on,
      withdrawn_at: nil,
      withdrawal_reason: nil
    )

    expect(
      TrainingPeriod.exists?(
        erroneous_withdrawn_training_period.id
      )
    ).to be(true)

    expect(ect_at_school_period.reload.finished_on).to be_nil
    expect(mentorship_period.reload.finished_on).to be_nil
  end
end
