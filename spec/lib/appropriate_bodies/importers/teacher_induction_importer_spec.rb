RSpec.describe AppropriateBodies::Importers::TeacherInductionImporter do
  def ci?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("CI", false))
  end

  subject(:induction_importer) do
    described_class.new(
      teachers_csv:,
      induction_period_csv:
    )
  end

  let(:ab_importer) do
    AppropriateBodies::Importers::AppropriateBodyImporter.new(
      data_csv: appropriate_body_csv,
      dfe_sign_in_mapping_csv:
    )
  end

  let(:dfe_sign_in_mapping_csv) { Rails.root.join("tmp/import/dfe-sign-in-mappings.csv") }
  let(:appropriate_body_csv) { Rails.root.join("tmp/import/appropriatebody.csv") }
  let(:teachers_csv) { Rails.root.join("tmp/import/teachers.csv") }
  let(:induction_period_csv) { Rails.root.join("tmp/import/inductionperiods.csv") }

  it "imports expected data", :aggregate_failures do
    skip "Skip testing CSVs in the pipeline" if ci?

    expect { ab_importer.import! }.not_to raise_error

    # 532 already on production
    expect(AppropriateBodyPeriod.count).to eq(532)

    expect { induction_importer.import! }.not_to raise_error

    # Passed: 669885
    # Failed: 407
    # FailedInWales: 8
    # Exempt: 1006852
    # None: 7
    # RequiredToComplete: 41093
    # InProgress: 80921
    #
    expect(Teacher.count).to eq(604_050)
    expect(Teacher.failed.count).to eq(317)
    expect(Teacher.failed_in_wales.count).to eq(2)
    expect(Teacher.passed.count).to eq(591_616) # 589402?
    expect(Teacher.exempt.count).to eq(12_110)

    expect(InductionPeriod.ongoing.count).to be_zero
    expect(InductionPeriod.ongoing.map { |ip| ip.teacher.trn }).to eq([])

    expect(InductionPeriod.count).to eq(636_342)
    expect(InductionPeriod.finished.count).to eq(InductionPeriod.count)
    expect(InductionPeriod.released.count).to eq(46_632)
    expect(InductionPeriod.failed.count).to eq(Teacher.failed.count + Teacher.failed_in_wales.count)
    expect(InductionPeriod.passed.count).to eq(Teacher.passed.count)

    # Number the TRS sync will grow by
    expect(InductionPeriod.released.joins(:teachers).distinct.count).to eq(1)

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

    expect(induction_period_frequency.values.sum).to eq(InductionPeriod.count) # 589973

    expect(induction_period_frequency).to eq({
      1 => 547_632,
      2 => 38_610,
      3 => 3466,
      4 => 240,
      5 => 20,
      6 => 3,
      7 => 2
    })

    # InductionPeriod.count - InductionPeriod.failed.count - InductionPeriod.passed.count

    expect(InductionExtension.count).to eq(3_490)

    expect(Event.count).to eq(1_280_307)
    expect(Event.where(body: "Imported from ECF1").count).to eq(1_272_545)
    expect(Event.where(body: "Imported from ECF1").count).to eq(
      Event.with_event_type(:induction_period_opened).count +
      Event.with_event_type(:teacher_fails_induction).count +
      Event.with_event_type(:teacher_passes_induction).count +
      Event.with_event_type(:induction_period_closed).count
    )
    expect(Event.with_event_type(:import_from_dqt).count).to eq(7_762)
    expect(Event.with_event_type(:induction_period_opened).count).to eq(InductionPeriod.count)
    expect(Event.with_event_type(:teacher_fails_induction).count).to eq(InductionPeriod.failed.count)
    expect(Event.with_event_type(:teacher_passes_induction).count).to eq(InductionPeriod.passed.count)
    expect(Event.with_event_type(:induction_period_closed).count).to eq(46_493)
  end
end
