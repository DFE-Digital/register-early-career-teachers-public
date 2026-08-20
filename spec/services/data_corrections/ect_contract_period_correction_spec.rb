RSpec.describe DataCorrections::ECTContractPeriodCorrection do
  subject(:correction) do
    described_class.new(
      training_period:,
      teacher_id:,
      current_contract_period_year: current_contract_period.year,
      replacement_contract_period_year: replacement_contract_period.year,
      replacement_schedule: supplied_replacement_schedule,
      replacement_school_partnership:
        supplied_replacement_school_partnership,
      replacement_expression_of_interest:
        supplied_replacement_expression_of_interest,
      allow_finished_training_period:
    )
  end

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:teacher_id) { teacher.id }
  let(:school) { FactoryBot.create(:school) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  let(:current_contract_period) do
    FactoryBot.create(:contract_period, year: 2026)
  end

  let(:replacement_contract_period) do
    FactoryBot.create(:contract_period, year: 2025)
  end

  let(:current_framework_agreement) do
    FactoryBot.create(
      :framework_agreement,
      lead_provider:,
      contract_period: current_contract_period
    )
  end

  let!(:replacement_framework_agreement) do
    FactoryBot.create(
      :framework_agreement,
      lead_provider:,
      contract_period: replacement_contract_period
    )
  end

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      teacher:,
      school:
    )
  end

  let(:current_schedule) do
    FactoryBot.create(
      :schedule,
      contract_period: current_contract_period
    )
  end

  let!(:replacement_schedule) do
    FactoryBot.create(
      :schedule,
      identifier: current_schedule.identifier,
      contract_period: replacement_contract_period
    )
  end

  let(:current_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      school:,
      framework_agreement: current_framework_agreement
    )
  end

  let!(:replacement_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      school:,
      framework_agreement: replacement_framework_agreement
    )
  end

  let(:current_expression_of_interest) { nil }

  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :provider_led,
      :unfinished,
      ect_at_school_period:,
      schedule: current_schedule,
      school_partnership: current_school_partnership,
      expression_of_interest: current_expression_of_interest
    )
  end

  let(:supplied_replacement_schedule) { nil }
  let(:supplied_replacement_school_partnership) { nil }
  let(:supplied_replacement_expression_of_interest) { nil }
  let(:allow_finished_training_period) { false }

  describe "#preview" do
    it "returns the proposed replacement without changing the period" do
      preview = nil

      expect { preview = correction.preview }
        .not_to(change { training_period.reload.schedule_id })

      expect(preview).to eq(
        contract_period: replacement_contract_period,
        schedule: replacement_schedule,
        school_partnership: replacement_school_partnership,
        expression_of_interest: nil
      )
    end
  end

  describe "#call" do
    it "updates the schedule and school partnership" do
      corrected_training_period = correction.call

      expect(corrected_training_period).to have_attributes(
        schedule: replacement_schedule,
        school_partnership: replacement_school_partnership,
        expression_of_interest: nil
      )

      expect(corrected_training_period.contract_period)
        .to eq(replacement_contract_period)
    end

    context "when the period uses an expression of interest" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :unfinished,
          :with_no_school_partnership,
          ect_at_school_period:,
          schedule: current_schedule,
          expression_of_interest: current_framework_agreement
        )
      end

      it "updates the expression of interest" do
        corrected_training_period = correction.call

        expect(corrected_training_period).to have_attributes(
          schedule: replacement_schedule,
          school_partnership: nil,
          expression_of_interest: replacement_framework_agreement
        )
      end
    end

    context "when the period has both associations" do
      let(:current_expression_of_interest) do
        current_framework_agreement
      end

      it "updates both associations" do
        corrected_training_period = correction.call

        expect(corrected_training_period).to have_attributes(
          schedule: replacement_schedule,
          school_partnership: replacement_school_partnership,
          expression_of_interest: replacement_framework_agreement
        )
      end
    end

    context "when a replacement schedule is supplied" do
      let(:supplied_replacement_schedule) do
        replacement_schedule
      end

      it "uses the supplied schedule" do
        expect(correction.call.schedule)
          .to eq(replacement_schedule)
      end
    end

    context "when a replacement school partnership is supplied" do
      let(:supplied_replacement_school_partnership) do
        replacement_school_partnership
      end

      it "uses the supplied school partnership" do
        expect(correction.call.school_partnership)
          .to eq(replacement_school_partnership)
      end
    end
  end

  describe "validation" do
    context "when the training period is for a mentor" do
      let(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          :unfinished,
          started_on: 1.year.ago
        )
      end

      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          :unfinished,
          :provider_led,
          mentor_at_school_period:,
          started_on: mentor_at_school_period.started_on
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period must be for an ECT"
          )
      end
    end

    context "when the training period belongs to another teacher" do
      let(:teacher_id) { FactoryBot.create(:teacher).id }

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period belongs to a different teacher"
          )
      end
    end

    context "when the training period is school-led" do
      before do
        training_period.update_columns(
          training_programme: "school_led"
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period must be provider-led"
          )
      end
    end

    context "when the training period is finished" do
      let(:finished_on) { Date.current }

      before do
        training_period.update!(finished_on:)
      end

      it "raises an error by default" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period must be ongoing"
          )
      end

      context "when correcting it has been explicitly allowed" do
        let(:allow_finished_training_period) { true }

        it "corrects the period without changing its dates" do
          started_on = training_period.started_on

          correction.call

          expect(training_period.reload).to have_attributes(
            started_on:,
            finished_on:,
            schedule: replacement_schedule,
            school_partnership: replacement_school_partnership
          )
        end
      end
    end

    context "when the training period has no schedule" do
      before do
        training_period.update_column(:schedule_id, nil)
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period has no schedule"
          )
      end
    end

    context "when the current contract-period year does not match" do
      subject(:correction) do
        described_class.new(
          training_period:,
          teacher_id:,
          current_contract_period_year: 2024,
          replacement_contract_period_year:
            replacement_contract_period.year
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period uses a different current contract period"
          )
      end
    end

    context "when the replacement contract period is unchanged" do
      subject(:correction) do
        described_class.new(
          training_period:,
          teacher_id:,
          current_contract_period_year:
            current_contract_period.year,
          replacement_contract_period_year:
            current_contract_period.year
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Replacement contract period is the current contract period"
          )
      end
    end

    context "when the replacement schedule has a different identifier" do
      let(:supplied_replacement_schedule) do
        FactoryBot.create(
          :schedule,
          identifier: "ecf-standard-january",
          contract_period: replacement_contract_period
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Replacement schedule uses a different identifier"
          )
      end
    end

    context "when the replacement schedule uses another contract period" do
      let(:other_contract_period) do
        FactoryBot.create(:contract_period, year: 2024)
      end

      let(:supplied_replacement_schedule) do
        FactoryBot.create(
          :schedule,
          identifier: current_schedule.identifier,
          contract_period: other_contract_period
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Replacement schedule uses the wrong contract period"
          )
      end
    end

    context "when the training period has no partnership or expression of interest" do
      before do
        training_period.update_columns(
          school_partnership_id: nil,
          expression_of_interest_id: nil
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Training period must have a school partnership or expression of interest"
          )
      end
    end

    context "when a supplied partnership belongs to another school" do
      let(:supplied_replacement_school_partnership) do
        FactoryBot.create(
          :school_partnership,
          school: FactoryBot.create(:school),
          framework_agreement: replacement_framework_agreement
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Partnership belongs to the wrong school"
          )
      end
    end

    context "when a supplied partnership changes the lead provider" do
      let(:other_framework_agreement) do
        FactoryBot.create(
          :framework_agreement,
          contract_period: replacement_contract_period
        )
      end

      let(:supplied_replacement_school_partnership) do
        FactoryBot.create(
          :school_partnership,
          school:,
          framework_agreement: other_framework_agreement
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Partnership changes the lead provider"
          )
      end
    end

    context "when a supplied partnership uses another contract period" do
      let(:other_contract_period) do
        FactoryBot.create(:contract_period, year: 2024)
      end

      let(:other_framework_agreement) do
        FactoryBot.create(
          :framework_agreement,
          lead_provider:,
          contract_period: other_contract_period
        )
      end

      let(:supplied_replacement_school_partnership) do
        FactoryBot.create(
          :school_partnership,
          school:,
          framework_agreement: other_framework_agreement
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Partnership uses the wrong contract period"
          )
      end
    end

    context "when a supplied expression of interest changes the lead provider" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :unfinished,
          :with_no_school_partnership,
          ect_at_school_period:,
          schedule: current_schedule,
          expression_of_interest: current_framework_agreement
        )
      end

      let(:supplied_replacement_expression_of_interest) do
        FactoryBot.create(
          :framework_agreement,
          contract_period: replacement_contract_period
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Expression of interest changes the lead provider"
          )
      end
    end

    context "when a supplied expression of interest uses another contract period" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          :unfinished,
          :with_no_school_partnership,
          ect_at_school_period:,
          schedule: current_schedule,
          expression_of_interest: current_framework_agreement
        )
      end

      let(:other_contract_period) do
        FactoryBot.create(:contract_period, year: 2024)
      end

      let(:supplied_replacement_expression_of_interest) do
        FactoryBot.create(
          :framework_agreement,
          lead_provider:,
          contract_period: other_contract_period
        )
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "Expression of interest uses the wrong contract period"
          )
      end
    end

    context "when no replacement schedule can be found" do
      before do
        replacement_schedule.destroy!
      end

      it "raises an error" do
        expect { correction.call }
          .to raise_error(
            described_class::InvalidCorrection,
            "No matching replacement schedule found"
          )
      end
    end
  end
end
