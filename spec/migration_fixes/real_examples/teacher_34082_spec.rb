describe "Real data check for teacher 34082" do
  let!(:teacher) { FactoryBot.create(:teacher, id: 34082) }
  let!(:lead_provider_3) { FactoryBot.create(:lead_provider, id: 1, name: "UCL Institute of Education") }
  let!(:lead_provider_2) { FactoryBot.create(:lead_provider, id: 3, name: "National Institute of Teaching") }
  let!(:delivery_partner_1) { FactoryBot.create(:delivery_partner, id: 171, name: "East Manchester Teaching School Hub") }
  let!(:delivery_partner_2) { FactoryBot.create(:delivery_partner, id: 136, name: "NIOT @ Star Academies (NW3)") }
  let!(:contract_period_2022) { FactoryBot.create(:contract_period, year: 2022) }
  let!(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let!(:schedule_1) { FactoryBot.create(:schedule, id: 50, identifier: "ecf-standard-september", contract_period: contract_period_2022) }
  let!(:schedule_2) { FactoryBot.create(:schedule, id: 20, identifier: "ecf-extended-september", contract_period: contract_period_2024) }
  let!(:school_1) { FactoryBot.create(:school) }
  let!(:school_2) { FactoryBot.create(:school) }
  let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, id: 7, lead_provider: lead_provider_3, contract_period: contract_period_2022) }
  let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, id: 20, lead_provider: lead_provider_2, contract_period: contract_period_2024) }
  let!(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, id: 19, lead_provider: lead_provider_3, contract_period: contract_period_2024) }
  let!(:lpdp_1) { FactoryBot.create(:lead_provider_delivery_partnership, id: 577, active_lead_provider: active_lead_provider_1, delivery_partner: delivery_partner_1) }
  let!(:lpdp_2) { FactoryBot.create(:lead_provider_delivery_partnership, id: 154, active_lead_provider: active_lead_provider_2, delivery_partner: delivery_partner_2) }
  let!(:lpdp_3) { FactoryBot.create(:lead_provider_delivery_partnership, id: 401, active_lead_provider: active_lead_provider_3, delivery_partner: delivery_partner_1) }
  let!(:school_partnership_1) { FactoryBot.create(:school_partnership, id: 70197, school: school_1, lead_provider_delivery_partnership: lpdp_1) }
  let!(:school_partnership_2) { FactoryBot.create(:school_partnership, id: 38127, school: school_2, lead_provider_delivery_partnership: lpdp_2) }
  let!(:school_partnership_3) { FactoryBot.create(:school_partnership, id: 16275, school: school_1, lead_provider_delivery_partnership: lpdp_3) }
  let!(:ect_at_school_period_1) { FactoryBot.create(:ect_at_school_period, id: 10400, teacher:, school: school_1, started_on: Date.new(2022, 9, 1), finished_on: Date.new(2024, 1, 2)) }
  let!(:ect_at_school_period_2) { FactoryBot.create(:ect_at_school_period, id: 10404, teacher:, school: school_2, started_on: Date.new(2026, 2, 25), finished_on: Date.new(2026, 2, 26)) }
  let!(:ect_at_school_period_3) { FactoryBot.create(:ect_at_school_period, id: 10412, teacher:, school: school_1, started_on: Date.new(2026, 2, 27), finished_on: Date.new(2026, 3, 6)) }
  
  let!(:training_period_1) { FactoryBot.create(:training_period, id: 136514, school_partnership: school_partnership_1, ect_at_school_period: ect_at_school_period_1, mentor_at_school_period: nil, started_on: Date.new(2022, 9, 1), finished_on: Date.new(2024, 1, 2), training_programme: "provider_led", withdrawn_at: nil, withdrawal_reason: nil, deferred_at: nil, deferral_reason: nil) }
  let!(:training_period_2) { FactoryBot.create(:training_period, id: 136520, school_partnership: school_partnership_2, ect_at_school_period: ect_at_school_period_2, mentor_at_school_period: nil, started_on: Date.new(2026, 2, 25), finished_on: Date.new(2026, 2, 26), training_programme: "provider_led", withdrawn_at: nil, withdrawal_reason: nil, deferred_at: nil, deferral_reason: nil) }
  let!(:training_period_3) { FactoryBot.create(:training_period, id: 136525, school_partnership: school_partnership_3, ect_at_school_period: ect_at_school_period_3, mentor_at_school_period: nil, started_on: Date.new(2026, 2, 27), finished_on: Date.new(2026, 3, 6), training_programme: "provider_led", withdrawn_at: Time.zone.parse("2026-03-06T15:45:06+00:00"), withdrawal_reason: "moved_school", deferred_at: nil, deferral_reason: nil) }

  let(:migration_fixes) do
    [
      {
        object_type: "TrainingPeriod",
        object_id: 136_514,
        action: "update",
        attributes: {
          withdrawn_at: "2026-03-06 15:45:06 +0000",
          withdrawal_reason: "moved_school",
        }
      },
      {
        object_type: "TrainingPeriod",
        object_id: 136_525,
        action: "delete",
        attributes: {}
      },
      {
        object_type: "ECTAtSchoolPeriod",
        object_id: 10_412,
        action: "delete",
        attributes: {}
      },
      {
        object_type: "TrainingPeriod",
        object_id: 136_520,
        action: "update",
        attributes: {
          finished_on: nil,
        }
      },
      {
        object_type: "ECTAtSchoolPeriod",
        object_id: 10404,
        action: "update",
        attributes: {
          finished_on: nil,
        }
      },
    ]
  end

  before do
    processor = MigrationFixes::Processor.new

    migration_fixes.each do |data_change|
      # convert from easy to read hash to string version as per CSV
      attrs = data_change[:attributes].stringify_keys.to_a.flatten.join(",")
      data_change[:attributes] = attrs

      processor.process!(data_change:)
    end
  end

  it "updates the training_period correctly" do
    expect(training_period_1.reload.withdrawn_at).to eq(Time.zone.parse("2026-03-06 15:45:06 +0000"))
  end

  it "removes training_period_3" do
    expect {
      training_period_3.reload
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "removes ect_at_school_period_3" do
    expect {
      ect_at_school_period_3.reload
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "removes the finished_on from training_period_2" do
    expect(training_period_2.reload.finished_on).to be_nil
  end

  it "removes the finished_on from ect_at_school_period_2" do
    expect(ect_at_school_period_2.reload.finished_on).to be_nil
  end
end
