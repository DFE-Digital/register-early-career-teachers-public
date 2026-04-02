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

  describe "fake teacher inductions" do
    let!(:ab_1) { FactoryBot.create(:appropriate_body_period, :local_authority) }
    let!(:ab_2) { FactoryBot.create(:appropriate_body_period, :local_authority) }
    let(:lisa) { Teacher.find_by(trn: "2345678") }
    let(:tina) { Teacher.find_by(trn: "6789012") }

    let(:teachers_csv) do
      <<~CSV
        trn,first_name,last_name,extension_length,extension_length_unit,induction_status
        1234567,Faye,Tozer,,,RequiredToComplete
        2345678,Lisa,Scott-Lee,,,InProgress
        3456789,Lee,Latchford-Evans,,,InProgress
        4567890,Ian,Watkins,,,Exempt
        5678901,Rachel,Stevens,,,Passed
        6789012,Tina,Barrett,,,Passed
        7890123,Paul,Cattermole,,,Failed
        8901234,Jon,Lee,,,Failed
        9012345,Bradley,McIntosh,,,FailedInWales
        0123456,Jo,O'Meara,,,Passed
        7777777,Hannah,Spearritt,,,None
      CSV
    end

    # 1. Faye (reject)
    # 2. Lisa (reject)
    # 3. Tina (...)
    # 4. Tina (pass)
    # 5. Paul (fail)
    # 6. Bradley (fail)
    let(:induction_period_csv) do
      <<~CSV
        appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
        #{ab_1.dqt_id},01/01/2012 00:00:00,10/31/2012 00:00:00,Core Induction Programme,,1234567
        #{ab_1.dqt_id},01/01/2012 00:00:00,10/31/2012 00:00:00,Core Induction Programme,,2345678
        #{ab_1.dqt_id},01/01/2012 00:00:00,10/31/2012 00:00:00,Core Induction Programme,,6789012
        #{ab_2.dqt_id},12/12/2021 00:00:00,10/31/2022 00:00:00,Core Induction Programme,0,6789012
        #{ab_2.dqt_id},12/12/2021 00:00:00,10/31/2022 00:00:00,Core Induction Programme,0,7890123
        #{ab_2.dqt_id},12/12/2021 00:00:00,10/31/2022 00:00:00,Core Induction Programme,0,9012345
      CSV
    end

    # Existing production data
    before do
      # unchanged since first import
      FactoryBot.create(:teacher, trn: "1234567", trs_first_name: "Faye", trs_induction_status: "RequiredToComplete")
      # failed since first import
      FactoryBot.create(:teacher, trn: "2345678", trs_first_name: "Lisa", trs_induction_status: "Failed")
    end

    it "imports expected data", :aggregate_failures do
      expect(AppropriateBodyPeriod.count).to eq(2)

      expect { induction_importer.import! }.not_to raise_error

      expect(Teacher.count).to eq(5) # 2 already + 3 imported
      expect(InductionPeriod.ongoing.count).to be_zero
      expect(Teacher.induction_status_passed.count).to eq(1)
      expect(Teacher.induction_status_failed.count).to eq(2) # 1 already + 1 imported
      expect(Teacher.induction_status_failed_in_wales.count).to eq(1)
      expect(InductionPeriod.count).to eq(4)

      # Lisa was InProgress and imported in the first round but has since failed
      # therefore her IPs should not be imported
      expect(lisa.induction_periods).to be_empty

      # Tina has Passed after two inductions
      # therefore her timeline should reflect this
      tina_timeline = Event.where(teacher_id: tina.id).order(:happened_at).pluck(:event_type)
      expect(tina_timeline).to eq(%w[
        induction_period_opened
        induction_period_closed
        induction_period_opened
        teacher_passes_induction
      ])
    end
  end

  describe "genuine teacher inductions" do
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

      expect(AppropriateBodyPeriod.count).to eq(532)

      expect { induction_importer.import! }.not_to raise_error

      expect(Teacher.count).to eq(589_839) # On prod where some already exist we will see 588_533 imported (1_306 delta)
      expect(Teacher.induction_status_in_progress.count).to be_zero
      expect(Teacher.induction_status_required_to_complete.count).to be_zero
      expect(Teacher.induction_status_failed.count).to eq(308)
      expect(Teacher.induction_status_failed_in_wales.count).to eq(2)
      expect(Teacher.induction_status_passed.count).to eq(589_222)
      expect(Teacher.induction_status_exempt.count).to eq(302)

      expect(InductionPeriod.ongoing.count).to be_zero
      expect(InductionPeriod.count).to eq(634_213)
      expect(InductionPeriod.finished.count).to eq(InductionPeriod.count)
      expect(InductionPeriod.released.count).to eq(44_681)

      expect(InductionPeriod.failed.count).to eq(Teacher.induction_status_failed.count + Teacher.induction_status_failed_in_wales.count)
      expect(InductionPeriod.passed.count).to eq(Teacher.induction_status_passed.count)

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

      teacher_induction_period_frequency = InductionPeriod.group(:teacher_id).count.values.group_by(&:itself).transform_values(&:count)

      expect(teacher_induction_period_frequency.values.sum).to eq(Teacher.count)

      expect(teacher_induction_period_frequency).to eq({
        1 => 548_978,
        2 => 37_581,
        3 => 3_070,
        4 => 193,
        5 => 13,
        6 => 2,
        7 => 2
      })

      expect(InductionExtension.count).to eq(3_472)

      expect(Event.count).to eq(1_275_068)
      expect(Event.where(body: "Imported from DQT").count).to eq(1_268_119)
      expect(Event.where(body: "Imported from DQT").count).to eq(
        Event.with_event_type(:induction_period_opened).count +
        Event.with_event_type(:teacher_fails_induction).count +
        Event.with_event_type(:teacher_passes_induction).count +
        Event.with_event_type(:induction_period_closed).count
      )
      expect(Event.with_event_type(:import_from_dqt).count).to eq(6_949)
      expect(Event.with_event_type(:induction_period_opened).count).to eq(InductionPeriod.count)
      expect(Event.with_event_type(:teacher_fails_induction).count).to eq(InductionPeriod.failed.count)
      expect(Event.with_event_type(:teacher_passes_induction).count).to eq(InductionPeriod.passed.count)

      expect(Event.with_event_type(:induction_period_closed).count).to eq(InductionPeriod.count - teacher_induction_period_frequency.values.sum)
    end
  end
end
