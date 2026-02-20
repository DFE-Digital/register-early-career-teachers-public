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

    let(:store) do
      FactoryBot.build(
        :session_repository,
        use_previous_ect_choices:,
        start_date: "3 September 2025"
      )
    end

    context "when provider-led is chosen" do
      let!(:lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: true,
          school_led_training_programme_chosen?: false,
          last_chosen_lead_provider: lead_provider,
          last_chosen_lead_provider_id: lead_provider.id
        )
      end

      context "and a reusable partnership exists for the registration contract period" do
        let(:active_lead_provider_2025) do
          FactoryBot.create(
            :active_lead_provider,
            lead_provider:,
            contract_period: current_contract_period
          )
        end

        let(:lpdp_2025) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            active_lead_provider: active_lead_provider_2025
          )
        end

        let!(:reusable_partnership) do
          FactoryBot.create(
            :school_partnership,
            school:,
            lead_provider_delivery_partnership: lpdp_2025
          )
        end

        it "is allowed" do
          expect(step.allowed?).to be(true)
        end

        context "with a start date on the last day of the next contract period, when today is the end of the current period" do
          around do |example|
            travel_to Date.new(2026, 5, 31) do
              example.run
            end
          end

          let(:next_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
          let(:active_lead_provider_2026) do
            FactoryBot.create(
              :active_lead_provider,
              lead_provider:,
              contract_period: next_contract_period
            )
          end

          let(:lpdp_2026) do
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              active_lead_provider: active_lead_provider_2026
            )
          end

          let!(:reusable_partnership) do
            FactoryBot.create(
              :school_partnership,
              school:,
              lead_provider_delivery_partnership: lpdp_2026
            )
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

      context "and no partnership is reusable but a previous EOI exists and the LP is available in the registration contract period" do
        let!(:previous_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

        let!(:previous_year_active_lead_provider) do
          FactoryBot.create(
            :active_lead_provider,
            lead_provider:,
            contract_period: previous_contract_period
          )
        end

        let!(:active_lead_provider_2025) do
          FactoryBot.create(
            :active_lead_provider,
            lead_provider:,
            contract_period: current_contract_period
          )
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

        context "with a start date on the last day of the next contract period, when today is the end of the current period" do
          let(:next_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
          let(:store) do
            FactoryBot.build(
              :session_repository,
              use_previous_ect_choices:,
              start_date: "31 May 2027"
            )
          end
          let!(:active_lead_provider_2026) do
            FactoryBot.create(
              :active_lead_provider,
              lead_provider:,
              contract_period: next_contract_period
            )
          end

          around do |example|
            travel_to Date.new(2026, 5, 31) do
              example.run
            end
          end

          it "is allowed" do
            expect(ActiveLeadProvider)
            .to receive(:exists?)
            .with(

              contract_period_year: 2026,
              lead_provider_id: active_lead_provider_2026.lead_provider_id
            ).and_call_original

            expect(step.allowed?).to be(true)
          end
        end
      end

      context "but there is no reusable partnership and no EOI" do
        before do
          finder = instance_double(SchoolPartnerships::FindReusablePartnership)
          allow(SchoolPartnerships::FindReusablePartnership).to receive(:new).and_return(finder)
          allow(finder).to receive(:call).and_return(nil)
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
        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: false,
          school_led_training_programme_chosen?: true,
          last_chosen_appropriate_body_id: appropriate_body_period.id
        )
      end

      it "is allowed (product expectation for school-led)" do
        expect(step.allowed?).to be(true)
      end
    end

    context "when school-led is chosen but last chosen appropriate body is missing" do
      before do
        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: false,
          school_led_training_programme_chosen?: true,
          last_chosen_appropriate_body_id: nil
        )
      end

      it "is not allowed" do
        expect(step.allowed?).to be(false)
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

        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: true,
          school_led_training_programme_chosen?: false,
          last_chosen_lead_provider: lead_provider
        )

        finder = instance_double(SchoolPartnerships::FindReusablePartnership)
        allow(SchoolPartnerships::FindReusablePartnership).to receive(:new).and_return(finder)
        allow(finder).to receive(:call).and_return(reusable_previous_year_partnership)
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

        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: true,
          school_led_training_programme_chosen?: false,
          last_chosen_lead_provider: lead_provider
        )

        finder = instance_double(SchoolPartnerships::FindReusablePartnership)
        allow(SchoolPartnerships::FindReusablePartnership).to receive(:new).and_return(finder)
        allow(finder).to receive(:call).and_return(reusable_current_year_partnership)
      end

      it "does not store school_partnership_to_reuse_id" do
        expect { step.save! }
          .not_to change { store[:school_partnership_to_reuse_id] }.from(nil)
      end
    end

    context "when school-led and user says yes" do
      let(:use_previous_ect_choices) { true }

      let(:step_params) do
        ActionController::Parameters.new(
          "use_previous_ect_choices" => { "use_previous_ect_choices" => "1" }
        )
      end

      before do
        allow(step.ect).to receive(:update).and_return(true)

        allow(school).to receive_messages(
          provider_led_training_programme_chosen?: false,
          school_led_training_programme_chosen?: true,
          last_chosen_appropriate_body_id: FactoryBot.create(:appropriate_body_period, :national).id
        )
      end

      it "does not set school_partnership_to_reuse_id" do
        expect { step.save! }
          .not_to change { store[:school_partnership_to_reuse_id] }.from(nil)
      end
    end
  end
end
