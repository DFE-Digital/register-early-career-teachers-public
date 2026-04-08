RSpec.describe AppropriateBodies::Importers::InductionPeriodParser do
  subject(:parser) do
    described_class.new(
      data_csv: sample_csv_data,
      logger: fake_logger
    )
  end

  let(:parsed) { parser.periods_by_trn }

  let(:parsed_to_record) do
    parsed.transform_values { |v| v.map(&:to_record) }
  end

  let(:fake_logger) { double(Logger, error: true) }

  let!(:ab_1) { FactoryBot.create(:appropriate_body_period, :local_authority) }
  let!(:ab_2) { FactoryBot.create(:appropriate_body_period, :local_authority) }
  let!(:ab_3) { FactoryBot.create(:appropriate_body_period, :local_authority) }
  let!(:ab_4) { FactoryBot.create(:appropriate_body_period, :local_authority) }
  let!(:ab_5) { FactoryBot.create(:appropriate_body_period, :local_authority) }

  let!(:ect_1) { FactoryBot.create(:teacher, :induction_passed) }
  let!(:ect_2) { FactoryBot.create(:teacher, :induction_failed_in_wales) }
  let!(:ect_3) { FactoryBot.create(:teacher, trs_induction_status: "None") }
  let!(:ect_4) { FactoryBot.create(:teacher, id: described_class::UNWANTED_TEACHER_IDS[0]) }
  let!(:ect_5) { FactoryBot.create(:teacher, id: described_class::UNWANTED_TEACHER_IDS[1]) }

  let(:sample_csv_data) do
    <<~CSV
      appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
      #{ab_1.dqt_id},01/01/2012 00:00:00,10/31/2012 00:00:00,Core Induction Programme,,#{ect_1.trn}
      #{ab_2.dqt_id},12/12/2021 00:00:00,10/31/2022 00:00:00,Core Induction Programme,0,#{ect_1.trn}
      #{ab_3.dqt_id},09/02/2022 00:00:00,11/13/2023 00:00:00,School-based Induction Programme,4.99,#{ect_2.trn}
      #{ab_4.dqt_id},10/31/2022 00:00:00,02/01/2023 00:00:00,Full Induction Programme,17,#{ect_3.trn}
      #{ab_5.dqt_id},10/31/2023 00:00:00,02/01/2024 00:00:00,,3.11,#{ect_3.trn}
    CSV
  end

  # unfiltered structs
  describe "#rows" do
    it "converts CSV::Rows to InductionPeriodParser::Rows" do
      expect(parser.rows).to all(be_a(described_class::Row))
    end

    it "converts all rows" do
      expect(parser.rows.count).to be(5)
    end

    describe "#induction_programme" do
      let(:mappings) do
        {
          ab_1.dqt_id => "pre_september_2021",
          ab_2.dqt_id => "cip",
          ab_3.dqt_id => "diy",
          ab_4.dqt_id => "fip",
          ab_5.dqt_id => "unknown"
        }
      end

      it "maps to a valid value" do
        mappings.each do |uuid, expected_value|
          row = parser.rows.find { |r| r.legacy_appropriate_body_id == uuid }
          expect(row.to_record.fetch(:induction_programme)).to eql(expected_value)
        end
      end
    end

    describe "#number_of_terms" do
      let(:mappings) do
        {
          ab_1.dqt_id => 0.0,
          ab_2.dqt_id => 0.0,
          ab_3.dqt_id => 5.0,
          ab_4.dqt_id => 16.0,
          ab_5.dqt_id => 3.1
        }
      end

      it "converts to a valid value" do
        mappings.each do |uuid, expected_value|
          row = parser.rows.find { |r| r.legacy_appropriate_body_id == uuid }
          expect(row.to_record.fetch(:number_of_terms)).to eql(expected_value)
        end
      end
    end
  end

  # filtered rows parsed and sorted and grouped
  describe "#periods_by_trn" do
    it "groups all trns" do
      expect(parsed.count).to be(3)
    end

    it "orders by trn" do
      expect(parsed.keys).to eq([ect_1.trn, ect_2.trn, ect_3.trn].sort)
    end

    context "when all rows are valid" do
      it "keeps all rows" do
        expect(parsed.values.flatten.count).to eq(parser.rows.count)
      end
    end

    describe "#to_record" do
      before do
        parsed[ect_2.trn].last.induction_status = trs_induction_status
      end

      let(:create_from_record) do
        InductionPeriod.create(
          **parsed_to_record[ect_2.trn].last,
          appropriate_body_period_id: ab_4.id,
          teacher_id: ect_2.id
        )
      end

      context "when the teacher has passed" do
        let(:trs_induction_status) { "Passed" }

        it "outputs valid attributes" do
          expect { create_from_record }.to change(InductionPeriod, :count).by(1)
          expect(InductionPeriod.passed.count).to eq(1)
        end
      end

      context "when the teacher has failed" do
        let(:trs_induction_status) { "Failed" }

        it "outputs valid attributes" do
          expect { create_from_record }.to change(InductionPeriod, :count).by(1)
          expect(InductionPeriod.failed.count).to eq(1)
        end
      end

      context "when the teacher has failed in Wales" do
        let(:trs_induction_status) { "FailedInWales" }

        it "outputs valid attributes" do
          expect { create_from_record }.to change(InductionPeriod, :count).by(1)
          expect(InductionPeriod.failed.count).to eq(1)
        end
      end
    end

    # it "orders inductions by start date" do
    #   # TODO: - add more dates
    # end

    # it "applies the ECT's induction status to their final period" do
    #   # TODO
    # end

    context "when started_on is nil" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},,,,3,#{ect_1.trn}
        CSV
      end

      it "does not import the row" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/started_on is nil/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when TRN is missing" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},01/01/2023 00:00:00,10/31/2023 00:00:00,Core Induction Programme,3,
        CSV
      end

      it "rejects the row because TRN is required" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/TRN or AB is missing/)
        expect(fake_logger).to have_received(:error).once.with(/dqt_id:/)
      end
    end

    context "when appropriate_body_id is missing" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          ,01/01/2023 00:00:00,10/31/2023 00:00:00,Core Induction Programme,3,#{ect_1.trn}
        CSV
      end

      it "rejects the row because appropriate_body_id is required" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/TRN or AB is missing/)
        expect(fake_logger).to have_received(:error).once.with(/trn:/)
      end
    end

    context "when finished_on is blank" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},01/01/2012 00:00:00,,,3,#{ect_1.trn}
        CSV
      end

      it "is rejected because it is ongoing" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/finished_on is nil/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when teacher_id is excluded" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},01/01/2012 00:00:00,01/02/2012 00:00:00,,1,#{ect_4.trn}
        CSV
      end

      it "is rejected because teacher exists with data" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/teacher already exists with inductions/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when started_on is invalid" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},01/01/0001 00:00:00,01/02/0001 00:00:00,,3,#{ect_1.trn}
        CSV
      end

      it "does not import the row" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/started_on is 0001-01-01/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when started_on is greater than finished_on" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.dqt_id},02/02/2023 00:00:00,01/01/2023 00:00:00,,3,#{ect_1.trn}
        CSV
      end

      it "does not import the row" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/started_on is greater than finished_on/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when the appropriate body ID is an offshore UUID" do
      let(:legacy_appropriate_body_id) do
        AppropriateBodies::Importers::OFFSHORE_DQT_UUIDS.sample
      end

      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{legacy_appropriate_body_id},01/01/2023 00:00:00,10/31/2023 00:00:00,Core Induction Programme,3,#{ect_1.trn}
        CSV
      end

      it "rejects the row and logs an error" do
        expect(parsed).to be_empty
        expect(fake_logger).to have_received(:error).once.with(/AB is offshore/)
        expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
      end
    end

    context "when the appropriate body does not exist in database but row is eligible for cutoff" do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          00000000-0000-0000-0000-000000000000,01/01/2024 00:00:00,10/31/2024 00:00:00,Core Induction Programme,3,#{ect_1.trn}
        CSV
      end

      it "leaves finished_on unchanged (cutoff not applied to non-existent ABs)" do
        expect(parsed).not_to be_empty
        period = parsed[ect_1.trn].first
        expect(period.finished_on).to eq(Date.new(2024, 10, 31))
      end

      it "does not raise an error during processing" do
        expect { parsed }.not_to raise_error
      end
    end

    describe "rebuilding periods" do
      let(:teachers_by_trn) { Teacher.where(trn: parsed.keys).index_by(&:trn) }

      before do
        parsed.each do |trn, periods|
          periods.last.induction_status = teachers_by_trn[trn].trs_induction_status
        end
      end

      context "when the start date is earlier than the statutory rollout date" do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            #{ab_1.dqt_id},08/01/1999 00:00:00,06/30/2022 00:00:00,Core Induction Programme,16,#{ect_1.trn}
          CSV
        end

        it "trims the start date to 1999-09-01" do
          expect(parsed_to_record).to eql(
            {
              ect_1.trn => [
                {
                  teacher_id: nil,
                  appropriate_body_period_id: nil,
                  outcome: :pass,
                  started_on: Date.new(1999, 9, 1),
                  finished_on: Date.new(2022, 6, 30),
                  induction_programme: "pre_september_2021",
                  number_of_terms: 16.0,
                }
              ]
            }
          )
        end
      end

      context "when the finish date is later than the import cutoff date" do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            #{ab_1.dqt_id},01/01/2019 00:00:00,10/31/2024 00:00:00,Core Induction Programme,3,#{ect_1.trn}
          CSV
        end

        it "trims the end date to 2024-08-31" do
          expect(parsed_to_record).to eql(
            {
              ect_1.trn => [
                {
                  teacher_id: nil,
                  appropriate_body_period_id: nil,
                  outcome: :pass,
                  started_on: Date.new(2019, 1, 1),
                  finished_on: Date.new(2024, 8, 31),
                  induction_programme: "pre_september_2021",
                  number_of_terms: 3.0,
                }
              ]
            }
          )
        end
      end

      context "when the finish date is at or before the import cutoff date" do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            #{ab_1.dqt_id},12/25/2022 00:00:00,08/30/2024 00:00:00,Core Induction Programme,9,#{ect_1.trn}
          CSV
        end

        it "leaves the dates unchanged" do
          expect(parsed_to_record).to eql(
            {
              ect_1.trn => [
                {
                  teacher_id: nil,
                  appropriate_body_period_id: nil,
                  outcome: :pass,
                  started_on: Date.new(2022, 12, 25),
                  finished_on: Date.new(2024, 8, 30),
                  induction_programme: "cip",
                  number_of_terms: 9.0,
                }
              ]
            }
          )
        end
      end

      context "when an ECT has one induction period with one AB" do
        context "and the period has a finished_on date" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,12/31/2022 00:00:00,Full Induction Programme,3,#{ect_3.trn}
            CSV
          end

          it "contains the finished period" do
            expect(parsed_to_record).to eql(
              {
                ect_3.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: nil,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 12, 31),
                    induction_programme: "fip",
                    number_of_terms: 3.0,
                  }
                ]
              }
            )
          end

          context "and the ECT passed" do
            let(:sample_csv_data) do
              <<~CSV
                appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
                #{ab_1.dqt_id},01/01/2022 00:00:00,12/31/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              CSV
            end

            it "contains the finished period and outcome" do
              expect(parsed_to_record).to eql(
                {
                  ect_1.trn => [
                    {
                      teacher_id: nil,
                      appropriate_body_period_id: nil,
                      outcome: :pass,
                      started_on: Date.new(2022, 1, 1),
                      finished_on: Date.new(2022, 12, 31),
                      induction_programme: "fip",
                      number_of_terms: 3.0,
                    }
                  ]
                }
              )
            end
          end

          context "and the ECT failed (in Wales)" do
            let(:sample_csv_data) do
              <<~CSV
                appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
                #{ab_1.dqt_id},01/01/2022 00:00:00,12/31/2022 00:00:00,Full Induction Programme,3,#{ect_2.trn}
              CSV
            end

            it "contains the finished period and outcome" do
              expect(parsed_to_record).to eql(
                {
                  ect_2.trn => [
                    {
                      teacher_id: nil,
                      appropriate_body_period_id: nil,
                      outcome: :fail,
                      started_on: Date.new(2022, 1, 1),
                      finished_on: Date.new(2022, 12, 31),
                      induction_programme: "fip",
                      number_of_terms: 3.0,
                    }
                  ]
                }
              )
            end
          end
        end
      end

      context "when an ECT has two induction periods that have the same programme type with one AB" do
        context "and the first period ends after the second period has started" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              #{ab_1.dqt_id},02/02/2022 00:00:00,04/04/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
            CSV
          end

          it "combines the two periods so the new period has the earliest start date and the latest finish date" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 4, 4),
                    induction_programme: "fip",
                    number_of_terms: 3.0,
                  }
                ]
              }
            )
          end
        end

        context "and the first period has an end date and terms but the second does not" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              #{ab_1.dqt_id},01/01/2022 00:00:00,,Core Induction Programme,,#{ect_1.trn}
            CSV
          end

          it "keeps the finished (first) period" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 3, 3),
                    induction_programme: "fip",
                    number_of_terms: 3.0,
                  }
                ]
              }
            )
          end
        end

        context "and the second period has an end date and terms but the first does not" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,,Core Induction Programme,,#{ect_1.trn}
              #{ab_1.dqt_id},01/01/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
            CSV
          end

          it "keeps the finished (second) period" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 3, 3),
                    induction_programme: "fip",
                    number_of_terms: 3.0,
                  }
                ]
              }
            )
          end
        end

        context "and the second period ends after the first period has started" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},02/02/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              #{ab_1.dqt_id},01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,4,#{ect_1.trn}
            CSV
          end

          it "combines the two periods so the new period has the earliest start date and the latest finish date and keeps the higher number of terms" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2012, 1, 1),
                    finished_on: Date.new(2012, 4, 4),
                    induction_programme: "pre_september_2021",
                    number_of_terms: 4.0,
                  }
                ]
              }
            )
          end
        end

        context "and the first period contains the second" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,2,#{ect_1.trn}
              #{ab_1.dqt_id},02/02/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,3,#{ect_1.trn}
            CSV
          end

          it "keeps the dates from the first" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2012, 1, 1),
                    finished_on: Date.new(2012, 4, 4),
                    induction_programme: "pre_september_2021",
                    number_of_terms: 3.0,
                  }
                ]
              }
            )
          end
        end

        context "and the second period contains the first" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},02/02/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,1,#{ect_1.trn}
              #{ab_1.dqt_id},01/01/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,4,#{ect_1.trn}
            CSV
          end

          it "only the second is kept" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2012, 1, 1),
                    finished_on: Date.new(2012, 4, 4),
                    induction_programme: "pre_september_2021",
                    number_of_terms: 4.0,
                  }
                ]
              }
            )
          end
        end
      end

      context "when an ECT has two induction periods that have different programme types with one AB" do
        context "and the periods do not overlap" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},01/01/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,4,#{ect_1.trn}
              #{ab_2.dqt_id},03/03/2022 00:00:00,05/05/2022 00:00:00,Core Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "both are kept" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: nil,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 3, 3),
                    induction_programme: "fip",
                    number_of_terms: 4.0,
                  },

                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 3, 3),
                    finished_on: Date.new(2022, 5, 5),
                    induction_programme: "cip",
                    number_of_terms: 2.0,
                  }
                ]
              }
            )
          end

          # it "notes" do
          #   expect(parsed[ect_1.trn]).to eql(
          #     [
          #       {
          #         notes: [],
          #       },
          #       {
          #         notes: []
          #       }
          #     ]
          #   )
          # end
        end

        context "and the periods overlap" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},01/01/2022 00:00:00,05/05/2022 00:00:00,Full Induction Programme,4,#{ect_1.trn}
              #{ab_2.dqt_id},04/04/2022 00:00:00,06/06/2022 00:00:00,Core Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "the earlier one is curtailed so it does not clash with the later one" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: nil,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 4, 4),
                    induction_programme: "fip",
                    number_of_terms: 4.0,
                  },
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 4, 4),
                    finished_on: Date.new(2022, 6, 6),
                    induction_programme: "cip",
                    number_of_terms: 2.0,
                  }
                ]
              }
            )
          end
        end
      end

      context "when an ECT has two induction period with different ABs" do
        context "and one contains the other" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},02/02/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,4,#{ect_1.trn}
              #{ab_1.dqt_id},01/01/2022 00:00:00,05/05/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "both are discarded due to conflict and logged" do
            expect(parsed.values.flatten.length).to be(0)
            expect(fake_logger).to have_received(:error).once.with(/two induction periods with different appropriate bodies where one contains the other/)
            expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
          end
        end

        context "and both start on the same day" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},02/02/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,4,#{ect_1.trn}
              #{ab_1.dqt_id},02/02/2022 00:00:00,05/05/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "both are discarded due to conflict and logged" do
            expect(parsed.values.flatten.length).to be(0)
            expect(fake_logger).to have_received(:error).once.with(/two induction periods with different appropriate bodies that start on the same day found/)
            expect(fake_logger).to have_received(:error).once.with(/trn: .* dqt_id:/)
          end
        end

        context "and the periods do not overlap" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},01/01/2022 00:00:00,03/03/2022 00:00:00,Full Induction Programme,4,#{ect_1.trn}
              #{ab_1.dqt_id},03/03/2022 00:00:00,05/05/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "both are kept" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: nil,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 3, 3),
                    induction_programme: "fip",
                    number_of_terms: 4.0,
                  },
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 3, 3),
                    finished_on: Date.new(2022, 5, 5),
                    induction_programme: "fip",
                    number_of_terms: 2.0,
                  }
                ]
              }
            )
          end
        end

        context "and the periods overlap" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_2.dqt_id},01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,1,#{ect_1.trn}
              #{ab_1.dqt_id},02/02/2012 00:00:00,05/05/2012 00:00:00,Full Induction Programme,4,#{ect_1.trn}
            CSV
          end

          it "both are kept but the earlier one is shortened to prevent overlap with the second" do
            expect(parsed[ect_1.trn].first.notes.first.fetch(:body)).to eq(
              "DQT held 2 overlapping induction periods for this teacher with different appropriate bodies. This record was cut off when the later one started to prevent overlaps."
            )

            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: nil,
                    started_on: Date.new(2012, 1, 1),
                    finished_on: Date.new(2012, 2, 2),
                    induction_programme: "pre_september_2021",
                    number_of_terms: 1.0,
                  },
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2012, 2, 2),
                    finished_on: Date.new(2012, 5, 5),
                    induction_programme: "pre_september_2021",
                    number_of_terms: 4.0,
                  }
                ]
              }
            )
          end
        end

        context "and current period starts before sibling but overlaps mid-range" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,03/15/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
              #{ab_2.dqt_id},02/15/2022 00:00:00,05/15/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
            CSV
          end

          it "adjusts the overlapping period to prevent concurrent inductions" do
            result = parsed_to_record[ect_1.trn]

            # Should have both periods, deconflicted
            expect(result.length).to be >= 1

            # Verify no overlaps
            result.each_with_index do |period1, i|
              result[(i + 1)..]&.each do |period2|
                expect(period1[:finished_on]).to be <= period2[:started_on]
              end
            end

            # The earlier period (ab_1) should be kept intact or shortened appropriately
            expect(result.first[:started_on]).to eq(Date.new(2022, 1, 1))
          end
        end
      end

      context "when an ECT has many overlapping periods" do
        context "with the same AB" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,02/01/2022 00:00:00,Full Induction Programme,1,#{ect_1.trn}
              #{ab_1.dqt_id},01/15/2022 00:00:00,03/01/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
              #{ab_1.dqt_id},02/01/2022 00:00:00,04/01/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              #{ab_1.dqt_id},03/01/2022 00:00:00,05/01/2022 00:00:00,Full Induction Programme,1,#{ect_1.trn}
              #{ab_1.dqt_id},04/01/2022 00:00:00,06/01/2022 00:00:00,Full Induction Programme,1,#{ect_1.trn}
            CSV
          end

          it "merges overlapping periods" do
            expect(parsed_to_record).to eql(
              {
                ect_1.trn => [
                  {
                    teacher_id: nil,
                    appropriate_body_period_id: nil,
                    outcome: :pass,
                    started_on: Date.new(2022, 1, 1),
                    finished_on: Date.new(2022, 6, 1),
                    induction_programme: "fip",
                    number_of_terms: 1.0, # FIXME: should this be a sum or the max?
                  }
                ]
              }
            )
          end
        end

        context "with different ABs" do
          let(:sample_csv_data) do
            <<~CSV
              appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
              #{ab_1.dqt_id},01/01/2022 00:00:00,03/01/2022 00:00:00,Full Induction Programme,1,#{ect_1.trn}
              #{ab_2.dqt_id},02/01/2022 00:00:00,04/01/2022 00:00:00,Core Induction Programme,2,#{ect_1.trn}
              #{ab_3.dqt_id},03/01/2022 00:00:00,05/01/2022 00:00:00,Full Induction Programme,3,#{ect_1.trn}
              #{ab_4.dqt_id},04/01/2022 00:00:00,06/01/2022 00:00:00,Core Induction Programme,2,#{ect_1.trn}
              #{ab_5.dqt_id},05/01/2022 00:00:00,07/01/2022 00:00:00,Full Induction Programme,2,#{ect_1.trn}
            CSV
          end

          it "periods do not overlap" do
            result = parsed_to_record[ect_1.trn]
            expect(result.length).to eq(5)

            result.each_with_index do |period1, i|
              result[(i + 1)..]&.each do |period2|
                expect(period1[:finished_on]).to be <= period2[:started_on]
              end
            end
          end
        end
      end
    end
  end
end
