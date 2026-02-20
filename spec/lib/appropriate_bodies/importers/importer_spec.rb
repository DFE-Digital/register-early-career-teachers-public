RSpec.describe AppropriateBodies::Importers::Importer, skip: "re-enable for local review" do
  # RSpec.describe AppropriateBodies::Importers::Importer do # TODO: skip for CI
  subject(:importer) do
    described_class.new(
      appropriate_body_csv:,
      teachers_csv:,
      induction_period_csv:,
      dfe_sign_in_mapping_csv:,
      dqt_csv:
    )
  end

  let(:appropriate_body_csv) { Rails.root.join("tmp/import/appropriatebody.csv") }
  let(:teachers_csv) { Rails.root.join("tmp/import/teachers.csv") }
  let(:induction_period_csv) { Rails.root.join("tmp/import/inductionperiods.csv") }
  let(:dfe_sign_in_mapping_csv) { Rails.root.join("tmp/import/dfe-sign-in-mappings.csv") }
  let(:dqt_csv) { Rails.root.join("tmp/import/old-abs.csv") }

  it "imports expected data", :aggregate_failures do
    expect { importer.import! }.not_to raise_error

    expect(AppropriateBodyPeriod.count).to eq(514)

    expect(Teacher.count).to eq(604_948)
    expect(Teacher.failed.count).to eq(317)
    expect(Teacher.failed_in_wales.count).to eq(2)
    expect(Teacher.passed.count).to eq(591_755)
    expect(Teacher.exempt.count).to eq(12_869)

    expect(InductionPeriod.count).to eq(631_973)
    expect(InductionPeriod.ongoing.count).to eq(0) # 2 when there should not be
    expect(InductionPeriod.finished.count).to eq(631_971)
    expect(InductionPeriod.without_outcome.count).to eq(46_643)
    expect(InductionPeriod.released.count).to eq(46_643)
    expect(InductionPeriod.with_outcome.count).to eq(585_330)
    expect(InductionPeriod.failed.count).to eq(305)
    expect(InductionPeriod.passed.count).to eq(585_025)

    expect(InductionExtension.count).to eq(3_495)

    expect(Event.count).to eq(1_267_852)
    expect(Event.with_event_type(:import_from_dqt).count).to eq(4_804)
    expect(Event.with_event_type(:induction_period_opened).count).to eq(631_973)
    expect(Event.with_event_type(:induction_period_closed).count).to eq(45_745)
    expect(Event.with_event_type(:teacher_fails_induction).count).to eq(305)
    expect(Event.with_event_type(:teacher_passes_induction).count).to eq(585_025)

    # assert every imported teacher has at least one induction period
    # assert that no induction periods start after a certain date
    # check why 2 ongoing appeared using XAN
  end
end
