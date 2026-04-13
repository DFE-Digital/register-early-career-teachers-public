RSpec.describe Schools::RegisterECTWizard::UsePreviousECTChoicesStep, type: :model do
  subject(:step) { wizard.current_step }

  let(:use_previous_ect_choices) { true }
  let(:step_params) { {} }
  let(:school) { FactoryBot.create(:school) }
  let(:store) do
    FactoryBot.build(
      :session_repository,
      use_previous_ect_choices:,
      start_date: "3 September 2025"
    )
  end

  let(:wizard) do
    FactoryBot.build(
      :register_ect_wizard,
      current_step: :use_previous_ect_choices,
      school:,
      store:,
      step_params:
    )
  end

  def stub_provider_led_school_choice(school:, lead_provider:)
    allow(school).to receive_messages(
      provider_led_training_programme_chosen?: true,
      school_led_training_programme_chosen?: false,
      last_chosen_lead_provider: lead_provider,
      last_chosen_lead_provider_id: lead_provider.id
    )
  end

  def stub_school_led_school_choice(school:, appropriate_body_id:)
    allow(school).to receive_messages(
      provider_led_training_programme_chosen?: false,
      school_led_training_programme_chosen?: true,
      last_chosen_appropriate_body_id: appropriate_body_id
    )
  end

  def stub_reusable_partnership_finder(return_value)
    finder = instance_double(SchoolPartnerships::FindReusablePartnership, call: return_value)
    allow(SchoolPartnerships::FindReusablePartnership).to receive(:new).and_return(finder)
  end

  def reassignable_provider_led_training_period(
    step,
    contract_period:,
    expression_of_interest_id: nil,
    started_on: Date.new(2021, 9, 1)
  )
    instance_double(
      TrainingPeriod,
      provider_led_training_programme?: true,
      training_programme: "provider_led",
      contract_period:,
      expression_of_interest_id:,
      started_on:
    ).tap do |previous_training_period|
      allow(step.ect).to receive(:previous_training_period).and_return(previous_training_period)
    end
  end

  def reassigned_registration_contract_period(step, contract_period:, previous_training_period:)
    resolver = instance_double(ContractPeriods::ForECTRegistration, call: contract_period)

    allow(ContractPeriods::ForECTRegistration).to receive(:new)
      .with(
        started_on: step.ect.normalized_start_date,
        previous_training_period:
      )
      .and_return(resolver)
  end

  describe "#initialize" do
    subject(:new_step) { described_class.new(wizard:, **params) }

    context "when use_previous_ect_choices is provided" do
      let(:params) { { use_previous_ect_choices: false } }

      it { expect(new_step.use_previous_ect_choices).to be(false) }
    end

    context "when no use_previous_ect_choices is provided" do
      let(:params) { {} }

      it { expect(new_step.use_previous_ect_choices).to be(true) }
    end
  end

  describe "#allowed?" do
    let!(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }

    context "when provider-led is chosen" do
      let!(:lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        stub_provider_led_school_choice(school:, lead_provider:)
      end

      context "and a reusable partnership exists for the registration contract period" do
        let(:active_lead_provider_2025) do
          FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
        end

        let(:lpdp_2025) do
          FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2025)
        end

        let!(:reusable_partnership) do
          FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2025)
        end

        it "is allowed" do
          expect(step.allowed?).to be(true)
        end

        context "with a start date on the last day of the next contract period, when today is the end of the current period" do
          around do |example|
            travel_to Date.new(2026, 5, 31) { example.run }
          end

          let(:next_contract_period) { FactoryBot.create(:contract_period, year: 2026) }

          let(:active_lead_provider_2026) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
          end

          let(:lpdp_2026) do
            FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2026)
          end

          let!(:reusable_partnership) do
            FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2026)
          end

          let(:store) do
            FactoryBot.build(
              :session_repository,
              use_previous_ect_choices:,
              start_date: "31 May 2027"
            )
          end

          it "finds a partnership in the next contract period, and the step is allowed" do
            expect(SchoolPartnerships::FindReusablePartnership)
              .to receive(:new)
              .with(
                school:,
                lead_provider: school.last_chosen_lead_provider,
                contract_period: next_contract_period
              )
              .and_call_original

            expect(step.allowed?).to be(true)
          end
        end
      end

      context "and previous provider-led training was in a payments-frozen contract period" do
        let!(:frozen_contract_period) do
          FactoryBot.create(:contract_period, year: 2021).tap do |contract_period|
            contract_period.update!(payments_frozen_at: 1.day.ago)
          end
        end

        let!(:reassigned_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

        let(:previous_training_period) do
          reassignable_provider_led_training_period(step, contract_period: frozen_contract_period)
        end

        before do
          reassigned_registration_contract_period(
            step,
            contract_period: reassigned_contract_period,
            previous_training_period:
          )
        end

        context "and a reusable partnership exists in the reassigned contract period" do
          let(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          let(:lpdp_2024) do
            FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider_2024)
          end

          let!(:reusable_partnership) do
            FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2024)
          end

          it "looks for a reusable partnership in the reassigned contract period" do
            expect(SchoolPartnerships::FindReusablePartnership)
              .to receive(:new)
              .with(
                school:,
                lead_provider: school.last_chosen_lead_provider,
                contract_period: reassigned_contract_period
              )
              .and_call_original

            expect(step.allowed?).to be(true)
          end
        end

        context "and only an earlier-year compatible partnership exists" do
          let!(:delivery_partner_alpha) { FactoryBot.create(:delivery_partner) }

          let(:previous_training_period) do
            reassignable_provider_led_training_period(
              step,
              contract_period: frozen_contract_period,
              expression_of_interest_id: nil
            )
          end

          let!(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          let!(:lpdp_2024) do
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              active_lead_provider: active_lead_provider_2024,
              delivery_partner: delivery_partner_alpha
            )
          end

          let!(:earlier_year_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: 2023,
              school:,
              lead_provider:,
              delivery_partner: delivery_partner_alpha
            )
          end

          it "is not allowed" do
            expect(step.allowed?).to be(false)
          end
        end

        context "and only a later-year compatible partnership exists" do
          let!(:delivery_partner_alpha) { FactoryBot.create(:delivery_partner) }

          let(:previous_training_period) do
            reassignable_provider_led_training_period(
              step,
              contract_period: frozen_contract_period,
              expression_of_interest_id: nil
            )
          end

          let!(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          let!(:lpdp_2024) do
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              active_lead_provider: active_lead_provider_2024,
              delivery_partner: delivery_partner_alpha
            )
          end

          let!(:later_year_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: 2025,
              school:,
              lead_provider:,
              delivery_partner: delivery_partner_alpha
            )
          end

          it "is not allowed" do
            expect(step.allowed?).to be(false)
          end
        end

        context "and only an earlier-year compatible partnership exists but a previous EOI exists and the LP is available in the reassigned contract period" do
          let!(:earlier_year_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: 2023,
              school:,
              lead_provider:,
              delivery_partner: FactoryBot.create(:delivery_partner)
            )
          end

          let(:previous_training_period) do
            reassignable_provider_led_training_period(
              step,
              contract_period: frozen_contract_period,
              expression_of_interest_id: previous_year_active_lead_provider.id
            )
          end

          let!(:previous_year_active_lead_provider) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: frozen_contract_period)
          end

          let!(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          it "is allowed via EOI fallback" do
            expect(step.allowed?).to be(true)
          end

          it "has no reusable partnership id" do
            expect(step.reusable_partnership_id).to be_nil
          end

          it "uses the reassigned registration contract period" do
            expect(step.registration_contract_period).to eq(reassigned_contract_period)
          end
        end

        context "and the previous training period used a confirmed partnership and the school has a recent EOI in the reassigned contract period" do
          let!(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          let!(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period, school:, started_on: Date.new(2024, 9, 1), finished_on: nil)
          end

          let(:previous_training_period) do
            reassignable_provider_led_training_period(
              step,
              contract_period: frozen_contract_period,
              expression_of_interest_id: nil
            )
          end

          before do
            FactoryBot.create(
              :training_period,
              ect_at_school_period:,
              training_programme: "provider_led",
              expression_of_interest: active_lead_provider_2024,
              school_partnership: nil,
              started_on: Date.new(2024, 9, 1),
              finished_on: nil
            )

            reassigned_registration_contract_period(
              step,
              contract_period: reassigned_contract_period,
              previous_training_period:
            )
          end

          it "is allowed via school EOI fallback" do
            expect(step.allowed?).to be(true)
          end

          it "has no reusable partnership id" do
            expect(step.reusable_partnership_id).to be_nil
          end
        end

        context "and the previous training period used a confirmed partnership and the school has a recent EOI in the reassigned contract period with a start date outside the contract period range" do
          let!(:active_lead_provider_2024) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: reassigned_contract_period)
          end

          let!(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period, school:, started_on: Date.new(2025, 9, 1), finished_on: nil)
          end

          let(:previous_training_period) do
            reassignable_provider_led_training_period(
              step,
              contract_period: frozen_contract_period,
              expression_of_interest_id: nil
            )
          end

          before do
            FactoryBot.create(
              :training_period,
              ect_at_school_period:,
              training_programme: "provider_led",
              expression_of_interest: active_lead_provider_2024,
              school_partnership: nil,
              started_on: Date.new(2025, 9, 1),
              finished_on: nil
            )

            reassigned_registration_contract_period(
              step,
              contract_period: reassigned_contract_period,
              previous_training_period:
            )
          end

          it "is allowed via school EOI fallback" do
            expect(step.allowed?).to be(true)
          end

          it "has no reusable partnership id" do
            expect(step.reusable_partnership_id).to be_nil
          end
        end
      end

      context "and no partnership is reusable but a previous EOI exists and the LP is available in the registration contract period" do
        let!(:previous_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

        let!(:previous_year_active_lead_provider) do
          FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period)
        end

        let!(:active_lead_provider_2025) do
          FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
        end

        let!(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            school:,
            started_on: Date.new(2024, 9, 1),
            finished_on: nil
          )
        end

        before do
          FactoryBot.create(
            :training_period,
            ect_at_school_period:,
            training_programme: "provider_led",
            expression_of_interest: previous_year_active_lead_provider,
            school_partnership: nil,
            started_on: Date.new(2024, 9, 1),
            finished_on: nil
          )
        end

        it "is allowed" do
          expect(step.allowed?).to be(true)
        end

        it "has no reusable partnership id" do
          expect(step.reusable_partnership_id).to be_nil
        end

        it "treats reuse as available" do
          expect(step.reusable_available?).to be(true)
        end

        context "with a start date on the last day of the next contract period, when today is the end of the current period" do
          around do |example|
            travel_to Date.new(2026, 5, 31) { example.run }
          end

          let(:next_contract_period) { FactoryBot.create(:contract_period, year: 2026) }

          let(:store) do
            FactoryBot.build(
              :session_repository,
              use_previous_ect_choices:,
              start_date: "31 May 2027"
            )
          end

          let!(:active_lead_provider_2026) do
            FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
          end

          it "is allowed" do
            expect(ActiveLeadProvider)
              .to receive(:exists?)
              .with(
                contract_period_year: 2026,
                lead_provider_id: active_lead_provider_2026.lead_provider_id
              )
              .and_call_original

            expect(step.allowed?).to be(true)
          end
        end
      end

      context "but there is no reusable partnership and no EOI" do
        before do
          stub_reusable_partnership_finder(nil)
        end

        it "is not allowed" do
          expect(step.allowed?).to be(false)
        end
      end
    end

    context "when provider-led is chosen but last chosen lead provider is missing" do
      before do
        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: true,
          school_led_training_programme_chosen?: false,
          last_chosen_lead_provider: nil
        )
      end

      it "is not allowed" do
        expect(step.allowed?).to be(false)
      end
    end

    context "when school-led is chosen and last chosen appropriate body is present" do
      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :national) }

      before do
        stub_school_led_school_choice(school:, appropriate_body_id: appropriate_body_period.id)
      end

      it "is allowed (product expectation for school-led)" do
        expect(step.allowed?).to be(true)
      end
    end

    context "when school-led is chosen but last chosen appropriate body is missing" do
      before do
        stub_school_led_school_choice(school:, appropriate_body_id: nil)
      end

      it "is not allowed" do
        expect(step.allowed?).to be(false)
      end
    end

    context "and the ECT has no previous training period but the school has a recent provider-led EOI training period for the LP" do
      let!(:lead_provider) { FactoryBot.create(:lead_provider) }

      let!(:active_lead_provider_2025) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
      end

      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: Date.new(2025, 9, 1),
          finished_on: nil
        )
      end

      before do
        stub_provider_led_school_choice(school:, lead_provider:)

        FactoryBot.create(
          :training_period,
          ect_at_school_period:,
          training_programme: "provider_led",
          expression_of_interest: active_lead_provider_2025,
          school_partnership: nil,
          started_on: Date.new(2025, 9, 1),
          finished_on: nil
        )
      end

      it "is allowed" do
        expect(step.allowed?).to be(true)
      end

      it "has no reusable partnership id" do
        expect(step.reusable_partnership_id).to be_nil
      end

      it "treats reuse as available via school EOI" do
        expect(step.reusable_available?).to be(true)
      end
    end
  end

  describe "#next_step" do
    context "when use_previous_ect_choices is true" do
      let(:use_previous_ect_choices) { true }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when use_previous_ect_choices is false" do
      let(:use_previous_ect_choices) { false }

      context "for independent schools" do
        let(:school) { FactoryBot.create(:school, :independent) }

        it { expect(step.next_step).to eq(:independent_school_appropriate_body) }
      end

      context "for state-funded schools" do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it { expect(step.next_step).to eq(:state_school_appropriate_body) }
      end
    end
  end

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:working_pattern) }
  end

  describe "#registration_contract_period" do
    let!(:frozen_contract_period) do
      FactoryBot.create(:contract_period, year: 2021).tap do |contract_period|
        contract_period.update!(payments_frozen_at: 1.day.ago)
      end
    end

    let!(:reassigned_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

    let(:previous_training_period) do
      reassignable_provider_led_training_period(step, contract_period: frozen_contract_period)
    end

    before do
      reassigned_registration_contract_period(
        step,
        contract_period: reassigned_contract_period,
        previous_training_period:
      )
    end

    it "returns the reassigned contract period" do
      expect(step.registration_contract_period).to eq(reassigned_contract_period)
    end
  end

  describe "#save!" do
    let!(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }

    let(:step_params) do
      ActionController::Parameters.new(
        "use_previous_ect_choices" => { "use_previous_ect_choices" => "0" }
      )
    end

    before do
      allow(ContractPeriod).to receive(:current).and_return(current_contract_period)
    end

    it "updates the wizard ect use_previous_ect_choices" do
      expect { step.save! }
        .to change(step.ect, :use_previous_ect_choices).from(true).to(false)
    end

    it "clears school_partnership_to_reuse_id when saving" do
      store[:school_partnership_to_reuse_id] = 123

      expect { step.save! }
        .to change { store[:school_partnership_to_reuse_id] }.from(123).to(nil)
    end

    context "when provider-led and user says yes and a reusable partnership is from a previous year" do
      let(:use_previous_ect_choices) { true }

      let(:step_params) do
        ActionController::Parameters.new(
          "use_previous_ect_choices" => { "use_previous_ect_choices" => "1" }
        )
      end

      let!(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }

      let!(:reusable_previous_year_partnership) do
        FactoryBot.create(
          :school_partnership,
          :for_year,
          year: 2024,
          school:,
          lead_provider:,
          delivery_partner:
        )
      end

      before do
        allow(step.ect).to receive(:update).and_return(true)
        stub_provider_led_school_choice(school:, lead_provider:)
        stub_reusable_partnership_finder(reusable_previous_year_partnership)
      end

      it "stores school_partnership_to_reuse_id" do
        expect { step.save! }
          .to change { store[:school_partnership_to_reuse_id] }.from(nil).to(reusable_previous_year_partnership.id)
      end
    end

    context "when provider-led and user says yes but reusable partnership is already in current year" do
      let(:use_previous_ect_choices) { true }

      let(:step_params) do
        ActionController::Parameters.new(
          "use_previous_ect_choices" => { "use_previous_ect_choices" => "1" }
        )
      end

      let!(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }

      let!(:active_lead_provider_2025) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
      end

      let!(:lpdp_2025) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lead_provider_2025,
          delivery_partner:
        )
      end

      let!(:reusable_current_year_partnership) do
        FactoryBot.create(
          :school_partnership,
          school:,
          lead_provider_delivery_partnership: lpdp_2025
        )
      end

      before do
        allow(step.ect).to receive(:update).and_return(true)
        stub_provider_led_school_choice(school:, lead_provider:)
        stub_reusable_partnership_finder(reusable_current_year_partnership)
      end

      it "does not store school_partnership_to_reuse_id" do
        expect { step.save! }
          .not_to change { store[:school_partnership_to_reuse_id] }.from(nil)
      end
    end

    context "when provider-led and user says yes and previous provider-led training was in a payments-frozen contract period" do
      let(:use_previous_ect_choices) { true }

      let(:step_params) do
        ActionController::Parameters.new(
          "use_previous_ect_choices" => { "use_previous_ect_choices" => "1" }
        )
      end

      let!(:lead_provider) { FactoryBot.create(:lead_provider) }
      let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }

      let!(:frozen_contract_period) do
        FactoryBot.create(:contract_period, year: 2021).tap do |contract_period|
          contract_period.update!(payments_frozen_at: 1.day.ago)
        end
      end

      let!(:reassigned_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

      let(:previous_training_period) do
        reassignable_provider_led_training_period(step, contract_period: frozen_contract_period)
      end

      before do
        allow(step.ect).to receive(:update).and_return(true)
        stub_provider_led_school_choice(school:, lead_provider:)

        reassigned_registration_contract_period(
          step,
          contract_period: reassigned_contract_period,
          previous_training_period:
        )
      end

      context "and a reusable partnership exists in the reassigned contract period year" do
        let!(:reusable_partnership_in_reassigned_year) do
          FactoryBot.create(
            :school_partnership,
            :for_year,
            year: 2024,
            school:,
            lead_provider:,
            delivery_partner:
          )
        end

        it "does not store school_partnership_to_reuse_id" do
          expect { step.save! }
            .not_to change { store[:school_partnership_to_reuse_id] }.from(nil)
        end
      end
    end

    context "when school-led and user says yes" do
      let(:use_previous_ect_choices) { true }

      let(:step_params) do
        ActionController::Parameters.new(
          "use_previous_ect_choices" => { "use_previous_ect_choices" => "1" }
        )
      end

      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :national) }

      before do
        allow(step.ect).to receive(:update).and_return(true)
        stub_school_led_school_choice(school:, appropriate_body_id: appropriate_body_period.id)
      end

      it "does not set school_partnership_to_reuse_id" do
        expect { step.save! }
          .not_to change { store[:school_partnership_to_reuse_id] }.from(nil)
      end
    end
  end
end
