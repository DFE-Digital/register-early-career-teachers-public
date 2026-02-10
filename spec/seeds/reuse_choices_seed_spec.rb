RSpec.describe "Reuse choices scenarios seed" do
  include Seeds::ReuseChoicesSeedHelpers

  let(:target_contract_period_year) { 2025 }

  before do
    run_reuse_choices_seed!(contract_period_year: target_contract_period_year)
  end

  describe "reference data" do
    it "creates the reference lead providers, delivery partners and appropriate body" do
      expect { reuse_reference_lead_provider }.not_to raise_error
      expect { reuse_reference_lead_provider_not_available }.not_to raise_error
      expect { reuse_reference_delivery_partner }.not_to raise_error
      expect { reuse_reference_delivery_partner_not_reusable }.not_to raise_error
      expect { reuse_reference_appropriate_body }.not_to raise_error
    end

    it "ensures the reusable lead provider is available in the target year" do
      expect(
        target_year_active_lead_provider_exists?(
          contract_period_year: target_contract_period_year,
          lead_provider: reuse_reference_lead_provider
        )
      ).to be(true)
    end
  end

  describe "scenario schools exist" do
    it "creates 17 scenario schools (URNs BASE..BASE+16) with matching GIAS records" do
      schools = School.where(urn: reuse_choices_urns).includes(:gias_school).order(:urn)

      expect(schools.size).to eq(17)
      expect(schools.all? { |s| s.gias_school.present? }).to be(true)
    end
  end

  describe "blank slate scenario" do
    it "creates the blank slate school with no last chosen programme choices" do
      school = reuse_school(offset: 0)

      expect(school.last_chosen_training_programme).to be_nil
      expect(school.last_chosen_lead_provider).to be_nil
      expect(school.last_chosen_appropriate_body).to be_nil
    end

    it "has at least one partnership option in the target year so the school can proceed" do
      school = reuse_school(offset: 0)

      expect(
        target_year_partnership_exists?(
          school:,
          contract_period_year: target_contract_period_year,
          lead_provider: reuse_reference_lead_provider,
          delivery_partner: reuse_reference_delivery_partner
        )
      ).to be(true)
    end
  end

  describe "reusable previous programme scenarios" do
    scenarios = [
      { offset: 1, previous_year: 2024, type: :partnership },
      { offset: 2, previous_year: 2024, type: :eoi },
      { offset: 3, previous_year: 2023, type: :partnership },
      { offset: 4, previous_year: 2023, type: :eoi },
      { offset: 5, previous_year: 2022, type: :partnership },
      { offset: 6, previous_year: 2022, type: :eoi },
      { offset: 7, previous_year: 2021, type: :partnership },
      { offset: 8, previous_year: 2021, type: :eoi },
    ]

    scenarios.each do |scenario|
      it "sets up #{scenario[:previous_year]} #{scenario[:type]} reusable (offset #{scenario[:offset]})" do
        school = reuse_school(offset: scenario.fetch(:offset))
        previous_year = scenario.fetch(:previous_year)
        type = scenario.fetch(:type)

        expect(school.last_chosen_training_programme).to eq("provider_led")
        expect(school.last_chosen_lead_provider).to eq(reuse_reference_lead_provider)
        expect(school.last_chosen_appropriate_body).to eq(reuse_reference_appropriate_body)

        ect_period = scenario_ect_period_for_school!(school:, previous_year:)
        expect(ect_period.school_reported_appropriate_body).to eq(reuse_reference_appropriate_body)

        induction_period = ect_period.teacher.induction_periods.find_by!(started_on: ect_period.started_on)
        expect(induction_period.appropriate_body).to eq(reuse_reference_appropriate_body)
        expect(induction_period.number_of_terms).to be_present

        training_period = scenario_provider_led_training_period_for_school!(school:, previous_year:)
        expect(training_period.schedule.identifier).to eq(reuse_choices_schedule_identifier)

        case type
        when :partnership
          expect(training_period.school_partnership).to be_present
          expect(training_period.expression_of_interest).to be_nil

          expect(
            target_year_partnership_exists?(
              school:,
              contract_period_year: target_contract_period_year,
              lead_provider: reuse_reference_lead_provider,
              delivery_partner: reuse_reference_delivery_partner
            )
          ).to be(true)

        when :eoi
          expect(training_period.school_partnership).to be_nil
          expect(training_period.expression_of_interest).to be_present

          expect(
            target_year_active_lead_provider_exists?(
              contract_period_year: target_contract_period_year,
              lead_provider: reuse_reference_lead_provider
            )
          ).to be(true)
        else
          raise "Unexpected type: #{type.inspect}"
        end
      end
    end
  end

  describe "not reusable previous programme scenarios" do
    scenarios = [
      { offset: 9,  previous_year: 2024, type: :partnership },
      { offset: 10, previous_year: 2024, type: :eoi },
      { offset: 11, previous_year: 2023, type: :partnership },
      { offset: 12, previous_year: 2023, type: :eoi },
      { offset: 13, previous_year: 2022, type: :partnership },
      { offset: 14, previous_year: 2022, type: :eoi },
      { offset: 15, previous_year: 2021, type: :partnership },
      { offset: 16, previous_year: 2021, type: :eoi },
    ]

    scenarios.each do |scenario|
      it "sets up #{scenario[:previous_year]} #{scenario[:type]} NOT reusable (offset #{scenario[:offset]})" do
        school = reuse_school(offset: scenario.fetch(:offset))
        previous_year = scenario.fetch(:previous_year)
        type = scenario.fetch(:type)

        expect(school.last_chosen_training_programme).to eq("provider_led")
        expect(school.last_chosen_appropriate_body).to eq(reuse_reference_appropriate_body)

        ect_period = scenario_ect_period_for_school!(school:, previous_year:)
        induction_period = ect_period.teacher.induction_periods.find_by!(started_on: ect_period.started_on)
        expect(induction_period.appropriate_body).to eq(reuse_reference_appropriate_body)

        training_period = scenario_provider_led_training_period_for_school!(school:, previous_year:)
        expect(training_period.schedule.identifier).to eq(reuse_choices_schedule_identifier)

        case type
        when :partnership
          expect(training_period.school_partnership).to be_present

          expect(
            target_year_active_lead_provider_exists?(
              contract_period_year: target_contract_period_year,
              lead_provider: reuse_reference_lead_provider
            )
          ).to be(true)

          expect(
            target_year_partnership_exists?(
              school:,
              contract_period_year: target_contract_period_year,
              lead_provider: reuse_reference_lead_provider,
              delivery_partner: reuse_reference_delivery_partner_not_reusable
            )
          ).to be(false)

        when :eoi
          expect(training_period.expression_of_interest).to be_present

          expect(
            target_year_active_lead_provider_exists?(
              contract_period_year: target_contract_period_year,
              lead_provider: reuse_reference_lead_provider_not_available
            )
          ).to be(false)
        else
          raise "Unexpected type: #{type.inspect}"
        end
      end
    end
  end
end
