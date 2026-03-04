RSpec.describe ECTAtSchoolPeriods::LeadProviderResolver do
  describe "#call" do
    subject(:resolver) { described_class.new(ect_at_school_period) }

    let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
    let(:school) { FactoryBot.create(:school) }

    let(:ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        :ongoing,
        school:,
        started_on: contract_period.started_on + 1.week
      )
    end

    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    let(:active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider:,
        contract_period:
      )
    end

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :ongoing,
        :provider_led,
        :with_only_expression_of_interest,
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on,
        expression_of_interest: active_lead_provider
      )
    end

    def withdrawn_attributes
      {
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first,
        finished_on: Time.zone.today
      }
    end

    def deferred_attributes
      {
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first,
        finished_on: Time.zone.today
      }
    end

    context "when CurrentTraining can resolve a lead provider" do
      it "returns the lead provider from CurrentTraining" do
        expect(resolver.call).to eq(lead_provider)
      end
    end

    context "when CurrentTraining cannot resolve" do
      before do
        fake_current_training = instance_double(
          ECTAtSchoolPeriods::CurrentTraining,
          lead_provider_via_school_partnership_or_eoi: nil
        )

        allow(ECTAtSchoolPeriods::CurrentTraining)
          .to receive(:new)
          .with(ect_at_school_period)
          .and_return(fake_current_training)
      end

      context "and latest TP is withdrawn provider-led" do
        before do
          training_period.update!(withdrawn_attributes)
        end

        it "falls back to the withdrawn lead provider" do
          expect(resolver.call).to eq(lead_provider)
        end
      end

      context "and latest TP is deferred provider-led" do
        before do
          training_period.update!(deferred_attributes)
        end

        it "falls back to the deferred lead provider" do
          expect(resolver.call).to eq(lead_provider)
        end
      end
    end
  end
end
