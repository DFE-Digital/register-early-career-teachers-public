describe "Real data check for teacher 39663" do
  let!(:teacher) { FactoryBot.create(:teacher, id: 39_663) }
  let!(:lead_provider_1) { FactoryBot.create(:lead_provider, id: 4, name: "Teach First") }
  let!(:delivery_partner_1) { FactoryBot.create(:delivery_partner, id: 149, name: "SFET Teaching School Hub") }
  let!(:contract_period_2023) { FactoryBot.create(:contract_period, year: 2023) }
  let!(:schedule_1) { FactoryBot.create(:schedule, id: 54, identifier: "ecf-standard-september", contract_period: contract_period_2023) }
  let!(:school_1) { FactoryBot.create(:school) }
  let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, id: 15, lead_provider: lead_provider_1, contract_period: contract_period_2023) }
  let!(:lpdp_1) { FactoryBot.create(:lead_provider_delivery_partnership, id: 728, active_lead_provider: active_lead_provider_1, delivery_partner: delivery_partner_1) }
  let!(:school_partnership_1) { FactoryBot.create(:school_partnership, id: 58_227, school: school_1, lead_provider_delivery_partnership: lpdp_1) }
  let!(:ect_at_school_period_1) { FactoryBot.create(:ect_at_school_period, id: 9468, teacher:, school: school_1, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2025, 7, 23)) }

  let!(:training_period_1) { FactoryBot.create(:training_period, id: 135_514, school_partnership: school_partnership_1, ect_at_school_period: ect_at_school_period_1, mentor_at_school_period: nil, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2025, 7, 23), training_programme: "provider_led", withdrawn_at: nil, withdrawal_reason: nil, deferred_at: nil, deferral_reason: nil) }

  let(:migration_fix) do
    {
      object_type: "TrainingPeriod",
      object_id: 135_514,
      action: "update",
      attributes: "withdrawn_at,2026-03-06 15:45:06 +0000,withdrawal_reason,moved_school",
    }
  end

  before do
    MigrationFixes::Processor.new.process!(data_change: migration_fix)
  end

  it "updates the record correctly" do
    expect(training_period_1.reload.withdrawn_at).to eq(Time.zone.parse("2026-03-06 15:45:06 +0000"))
    expect(training_period_1.withdrawal_reason).to eq("moved_school")
  end
end
