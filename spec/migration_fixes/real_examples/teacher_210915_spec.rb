describe "Real data check for teacher 210915 (missing training period and declarations)" do
  let!(:teacher) { FactoryBot.create(:teacher, id: 210915) }
  let!(:school_1) { FactoryBot.create(:school) }
  let!(:mentor_at_school_period_1) { FactoryBot.create(:mentor_at_school_period, id: 115121, teacher:, school: school_1, started_on: Date.new(2025, 5, 29), finished_on: nil) }

  # dependencies referenced in migration_fixes
  let!(:lead_provider) { FactoryBot.create(:lead_provider, id: 6, name: "Ambition Institute") }
  let!(:delivery_partner) { FactoryBot.create(:delivery_partner, id: 221, name: "The Three Rivers Teaching School Hub") }
  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:lpdp) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, id: 47614, school: school_1, lead_provider_delivery_partnership: lpdp) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2023, mentor_funding_enabled: false) }
  let!(:schedule) { FactoryBot.create(:schedule, id: 54, identifier: "ecf-standard-september", contract_period:) }
  let!(:statement_1) { FactoryBot.create(:statement, id: 628, contract_period:) }
  let!(:statement_2) { FactoryBot.create(:statement, id: 220, contract_period:) }

  let(:migration_fixes) do
    [
      {
        object_type: "MentorAtSchoolPeriod",
        object_id: 115_121,
        action: "update",
        attributes: {
          started_on: "2023-09-01",
        }
      },
      {
        object_type: "TrainingPeriod",
        object_id: "TP1",
        action: "create",
        attributes: {
          mentor_at_school_period_id: 115121,
          started_on: "2023-09-01",
          finished_on: "2025-05-29",
          training_programme: "provider_led",
          school_partnership_id: 47614,
          schedule_id: 54,
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "started",
          declaration_date: "2023-09-22",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "bceae3c7-078a-4ccc-bcc2-27bf55d84380",
          api_updated_at: "2026-01-16T13:49:01.509+00:00",
          created_at: "2025-12-15T21:20:23.473+00:00",
          payment_statement_id: 628,
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "retained-1",
          declaration_date: "2024-02-01",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "d766e6e7-3ff0-41d7-8ab1-cb8b853553a7",
          api_updated_at: "2026-01-16T13:49:02.787+00:00",
          created_at: "2025-12-15T21:20:24.358+00:00",
          payment_statement_id: 628,
          evidence_type: "training-event-attended",
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "retained-2",
          declaration_date: "2024-07-02",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "cf067e92-95dd-462f-b61f-5e6113e7e642",
          api_updated_at: "2026-01-16T13:49:02.378+00:00",
          created_at: "2025-12-15T21:20:25.494+00:00",
          payment_statement_id: 628,
          evidence_type: "training-event-attended",
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "retained-3",
          declaration_date: "2024-11-21",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "4fac8f63-2f41-49eb-8bc8-9311ac55be6b",
          api_updated_at: "2026-01-16T13:48:56.196+00:00",
          created_at: "2025-12-15T21:20:27.839+00:00",
          payment_statement_id: 628,
          evidence_type: "training-event-attended",
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "retained-4",
          declaration_date: "2025-01-24",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "c3cc8afc-3313-4499-968e-34621bdad012",
          api_updated_at: "2026-01-16T13:49:01.868+00:00",
          created_at: "2025-12-15T21:20:28.726+00:00",
          payment_statement_id: 628,
          evidence_type: "self-study-material-completed",
        }
      },
      {
        object_type: "Declaration",
        object_id: nil,
        action: "create",
        attributes: { 
          declaration_type: "completed",
          declaration_date: "2025-05-29",
          training_period_id: "TP1",
          delivery_partner_when_created_id: 221,
          payment_status: "paid",
          api_id: "409850ab-5471-4406-8f21-fbfff59f4531",
          api_updated_at: "2025-08-19T16:06:49.541+01:00",
          created_at: "2025-05-30T22:17:42.849+01:00",
          payment_statement_id: 220,
          evidence_type: "self-study-material-completed",
        }
      },
    ]
  end

  let(:processor) { MigrationFixes::Processor.new }

  before do
    migration_fixes.each do |data_change|
      # convert from easy to read hash to string version as per CSV
      attrs = data_change[:attributes].stringify_keys.to_a.flatten.join(",")
      data_change[:attributes] = attrs

      processor.process!(data_change:)
    end
  end

  it "updates the record correctly" do
    expect(mentor_at_school_period_1.reload.started_on).to eq(Date.new(2023, 9, 1))
  end

  it "creates a new training_period" do
    training_period = mentor_at_school_period_1.reload.training_periods.first

    expect(training_period.started_on).to eq(Date.new(2023, 9, 1))
    expect(training_period.finished_on).to eq(Date.new(2025, 5, 29))
    expect(training_period.training_programme).to eq "provider_led"
    expect(training_period.school_partnership).to eq school_partnership
  end

  it "adds the declarations correctly" do
    training_period = mentor_at_school_period_1.reload.training_periods.first
    declarations = training_period.declarations
    expect(declarations.count).to eq(6)
    %w[started retained-1 retained-2 retained-3 retained-4 completed].each do |declaration_type|
      expect(declarations.find_by(declaration_type:)).to be_present
    end
  end
end
