RSpec.describe Teachers::ECTWithdrawalHistoryCorrection do
  subject(:correct_withdrawal_history) do
    described_class.new(
      ect_at_school_period:,
      source_training_period:,
      target_training_period:,
      corrected_finished_on:,
      author:
    ).correct!
  end

  let(:author) { Events::SystemAuthor.new }

  let(:ect_started_on) { Date.new(2023, 9, 11) }
  let(:target_finished_on) { Date.new(2023, 11, 23) }
  let(:corrected_finished_on) { Date.new(2023, 11, 10) }

  let(:source_started_on) { Date.new(2025, 10, 7) }
  let(:source_finished_on) { Date.new(2025, 11, 6) }
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

  let!(:target_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on: ect_started_on,
      finished_on: target_finished_on,
      withdrawn_at: nil,
      withdrawal_reason: nil
    )
  end

  let!(:source_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :provider_led,
      ect_at_school_period:,
      started_on: source_started_on,
      finished_on: source_finished_on,
      withdrawn_at:,
      withdrawal_reason: "other"
    )
  end

  describe "#correct!" do
    it "moves the withdrawal details onto the target training period" do
      correct_withdrawal_history

      expect(target_training_period.reload).to have_attributes(
        withdrawn_at:,
        withdrawal_reason: "other"
      )
    end

    it "changes the target training period end date" do
      correct_withdrawal_history

      expect(target_training_period.reload.finished_on)
        .to eq(corrected_finished_on)
    end

    it "removes the source training period" do
      expect { correct_withdrawal_history }
        .to change {
          TrainingPeriod.exists?(source_training_period.id)
        }
        .from(true)
        .to(false)
    end

    it "finishes the ECT-at-school period" do
      correct_withdrawal_history

      expect(ect_at_school_period.reload.finished_on)
        .to eq(corrected_finished_on)
    end

    it "finishes the linked mentorship period" do
      correct_withdrawal_history

      expect(mentorship_period.reload.finished_on)
        .to eq(corrected_finished_on)
    end

    it "does not record events" do
      expect { correct_withdrawal_history }
        .not_to change(Event, :count)
    end

    context "when the source and target training periods are the same" do
      subject(:correct_withdrawal_history) do
        described_class.new(
          ect_at_school_period:,
          source_training_period: target_training_period,
          target_training_period:,
          corrected_finished_on:,
          author:
        ).correct!
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source and target training periods must be different"
          )
      end
    end

    context "when the source training period belongs to another ECT-at-school period" do
      let(:other_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          started_on: source_started_on,
          finished_on: nil
        )
      end

      let(:source_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          ect_at_school_period: other_ect_at_school_period,
          started_on: source_started_on,
          finished_on: source_finished_on,
          withdrawn_at:,
          withdrawal_reason: "other"
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period does not belong to the ECT-at-school period"
          )
      end
    end

    context "when the target training period belongs to another ECT-at-school period" do
      let(:other_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          started_on: ect_started_on,
          finished_on: nil
        )
      end

      let(:target_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          ect_at_school_period: other_ect_at_school_period,
          started_on: ect_started_on,
          finished_on: target_finished_on,
          withdrawn_at: nil,
          withdrawal_reason: nil
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period does not belong to the ECT-at-school period"
          )
      end
    end

    context "when the ECT-at-school period is already finished" do
      before do
        ect_at_school_period.update_columns(
          finished_on: corrected_finished_on
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "ECT-at-school period is already finished"
          )
      end
    end

    context "when the corrected finish date is before the ECT-at-school period starts" do
      let(:corrected_finished_on) { ect_started_on - 1.day }

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Corrected finish date is before the ECT-at-school period start date"
          )
      end
    end

    context "when the target training period starts after the corrected finish date" do
      before do
        target_training_period.update!(
          started_on: corrected_finished_on + 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period starts after the corrected finish date"
          )
      end
    end

    context "when the target training period finishes before the corrected finish date" do
      before do
        target_training_period.update!(
          finished_on: corrected_finished_on - 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period finishes before the corrected finish date"
          )
      end
    end

    context "when the source training period starts before the corrected finish date" do
      before do
        source_training_period.update_columns(
          started_on: corrected_finished_on - 1.day
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period starts before the corrected finish date"
          )
      end
    end

    context "when the target training period already has withdrawal details" do
      before do
        target_training_period.update!(
          withdrawn_at: Time.zone.parse("2024-01-01T12:00:00Z"),
          withdrawal_reason: "other"
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period already has withdrawal details"
          )
      end
    end

    context "when the source training period has no withdrawal timestamp" do
      before do
        source_training_period.update_columns(
          withdrawn_at: nil
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period has incomplete withdrawal details"
          )
      end
    end

    context "when the source training period has no withdrawal reason" do
      before do
        source_training_period.update_columns(
          withdrawal_reason: nil
        )
      end

      it "raises an error" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period has incomplete withdrawal details"
          )
      end
    end

    context "when the target training period has declarations" do
      before do
        FactoryBot.create(
          :declaration,
          :eligible,
          training_period: target_training_period
        )
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period has declarations"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when the target training period has events" do
      before do
        allow(target_training_period.events)
          .to receive(:exists?)
          .and_return(true)
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Target training period has events"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when the source training period has declarations" do
      before do
        FactoryBot.create(
          :declaration,
          :eligible,
          training_period: source_training_period
        )
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period has declarations"
          )

        expect_records_to_remain_unchanged
      end
    end

    context "when the source training period has events" do
      before do
        allow(source_training_period.events)
          .to receive(:exists?)
          .and_return(true)
      end

      it "raises an error without changing the records" do
        expect { correct_withdrawal_history }
          .to raise_error(
            RuntimeError,
            "Source training period has events"
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
    expect(target_training_period.reload).to have_attributes(
      finished_on: target_finished_on,
      withdrawn_at: nil,
      withdrawal_reason: nil
    )

    expect(TrainingPeriod.exists?(source_training_period.id))
      .to be(true)

    expect(ect_at_school_period.reload.finished_on)
      .to be_nil

    expect(mentorship_period.reload.finished_on)
      .to be_nil
  end
end
