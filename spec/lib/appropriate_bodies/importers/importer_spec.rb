# RSpec.describe AppropriateBodies::Importers::Importer, skip: "re-enable for local review" do
RSpec.describe AppropriateBodies::Importers::Importer do # TODO: skip for CI
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

    expect(AppropriateBodyPeriod.count).to eq(509)

    expect(Teacher.count).to eq(604_047)
    expect(Teacher.failed.count).to eq(317)
    expect(Teacher.failed_in_wales.count).to eq(2)
    expect(Teacher.passed.count).to eq(591_615)
    expect(Teacher.exempt.count).to eq(12_108)

    expect(InductionPeriod.count).to eq(631_022)
    expect(InductionPeriod.ongoing.count).to eq(0) # 1
    expect(InductionPeriod.finished.count).to eq(InductionPeriod.count)
    expect(InductionPeriod.released.count).to eq(45_832)
    expect(InductionPeriod.failed.count).to eq(305)
    expect(InductionPeriod.passed.count).to eq(584_885)

    expect(
      InductionPeriod.released.count + InductionPeriod.failed.count + InductionPeriod.passed.count
    ).to eq(
      InductionPeriod.count
    )

    expect(
      InductionPeriod.without_outcome.count + InductionPeriod.with_outcome.count
    ).to eq(
      InductionPeriod.count
    )

    induction_period_frequency = InductionPeriod.group(:teacher_id).count.values.group_by(&:itself).transform_values(&:count)
    expect(induction_period_frequency).to eq({
      1 => 544_506,
      2 => 37_855,
      3 => 3256,
      4 => 229,
      6 => 3,
      5 => 18,
      7 => 2
    })

    # InductionPeriod.count - InductionPeriod.failed.count - InductionPeriod.passed.count

    expect(InductionExtension.count).to eq(3_490)

    expect(Event.count).to eq(1_266_706)
    expect(Event.with_event_type(:import_from_dqt).count).to eq(4_798)
    expect(Event.with_event_type(:induction_period_opened).count).to eq(InductionPeriod.count)
    expect(Event.with_event_type(:teacher_fails_induction).count).to eq(InductionPeriod.failed.count)
    expect(Event.with_event_type(:teacher_passes_induction).count).to eq(InductionPeriod.passed.count)
    expect(Event.with_event_type(:induction_period_closed).count).to eq(45_696) # >= InductionPeriod.released.count
  end
end
