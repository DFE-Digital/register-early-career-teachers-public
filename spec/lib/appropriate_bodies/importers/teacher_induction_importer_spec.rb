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

    # prewarm the database by populating ABs
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
    expect(Teacher.count).to eq(590_025)
    expect(Teacher.failed.count).to eq(308)
    expect(Teacher.failed_in_wales.count).to eq(2)
    expect(Teacher.passed.count).to eq(589_401)
    expect(Teacher.exempt.count).to eq(309)

    expect(InductionPeriod.ongoing.count).to be_zero
    expect(InductionPeriod.count).to eq(636_398)
    expect(InductionPeriod.finished.count).to eq(InductionPeriod.count)

    # InductionPeriod.released IS COUNTING THE PRE-PASS AND PRE-FAIL IPS ?
    expect(InductionPeriod.released.count).to eq(46_687) # ?

    # FIXME: FailedInWales aren't getting marked as inductione fails (2 missing)
    expect(InductionPeriod.failed.count).to eq(Teacher.failed.count + Teacher.failed_in_wales.count)
    expect(InductionPeriod.passed.count).to eq(Teacher.passed.count)

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

    # teachers =
    #   Teacher.select(
    #     "teachers.*",
    #     "COUNT(induction_periods.id) OVER (PARTITION BY teachers.id) AS periods_count"
    #   ).left_joins(:induction_periods).distinct

    # teachers_with_zero = teachers.select { |t| t.periods_count.to_i == 0 }
    # teachers_with_one = teachers.select { |t| t.periods_count.to_i == 1 }
    # teachers_with_multiple = teachers.select { |t| t.periods_count.to_i > 1 }

    # expect(teachers_with_zero.count).to eq(0)
    # expect(teachers_with_one.count + teachers_with_multiple.count).to eq(Teacher.count)

    induction_period_frequency = InductionPeriod.group(:teacher_id).count.values.group_by(&:itself).transform_values(&:count)
    # FIXME: IP frequency tally does NOT total IP total 590025
    expect(induction_period_frequency.values.sum).to eq(InductionPeriod.count)
    expect(induction_period_frequency).to eq({
      1 => 547_680,
      2 => 38_614,
      3 => 3466,
      4 => 240,
      5 => 20,
      6 => 3,
      7 => 2
    })

    # induction_period_frequency.values.sum - 547_632 = 42341
    # InductionPeriod.count - 547_632 = 88710
    # number of inductions when a teacher has multiple Ips
    # InductionPeriod.count - Teacher.count = 34570
    # InductionPeriod.count - InductionPeriod.failed.count - InductionPeriod.passed.count

    expect(InductionExtension.count).to eq(3473)

    expect(Event.count).to eq(1_280_225)
    expect(Event.where(body: "Imported from DQT").count).to eq(1_272_482)
    expect(Event.where(body: "Imported from DQT").count).to eq(
      Event.with_event_type(:induction_period_opened).count +
      Event.with_event_type(:teacher_fails_induction).count +
      Event.with_event_type(:teacher_passes_induction).count +
      Event.with_event_type(:induction_period_closed).count
    )
    expect(Event.with_event_type(:import_from_dqt).count).to eq(7743)
    expect(Event.with_event_type(:induction_period_opened).count).to eq(InductionPeriod.count)
    expect(Event.with_event_type(:teacher_fails_induction).count).to eq(InductionPeriod.failed.count)
    expect(Event.with_event_type(:teacher_passes_induction).count).to eq(InductionPeriod.passed.count)

    # FIXME: some releases then finish with a pass, work out how to test
    # 1 IP = pass / fail
    # 2 IP =  release + pass / fail
    # 3 IP = 2 releases + pass / fail
    #
    # InductionPeriod.released.count = 46_689
    expect(Event.with_event_type(:induction_period_closed).count).to eq(46_373)
  end
end
