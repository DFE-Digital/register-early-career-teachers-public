describe AppropriateBodies::Importers::InductionPeriodImporter do
  let!(:ab_1) { FactoryBot.create(:appropriate_body, legacy_id: '025e61e7-ec32-eb11-a813-000d3a228dfc') }
  let!(:ab_2) { FactoryBot.create(:appropriate_body, legacy_id: '1ddf3e82-c1ae-e311-b8ed-005056822391') }
  let!(:ab_3) { FactoryBot.create(:appropriate_body, legacy_id: 'ef1c5e56-a8e6-41e2-a47d-c75a098cd61f') }
  let!(:ab_4) { FactoryBot.create(:appropriate_body, legacy_id: '67fc4692-2b90-4a80-8131-795eb93bc496') }
  let!(:ab_5) { FactoryBot.create(:appropriate_body, legacy_id: 'f4837bce-28ae-46d0-aae7-d49f1d8f62e3') }

  let!(:ect_1) { FactoryBot.create(:teacher, trn: '2600071') }
  let!(:ect_2) { FactoryBot.create(:teacher, trn: '1666461') }
  let!(:ect_3) { FactoryBot.create(:teacher, trn: '2600049') }

  let(:sample_csv_data) do
    <<~CSV
      appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
      #{ab_1.legacy_id},01/01/2012 00:00:00,10/31/2012 00:00:00,Core Induction Programme,3,2600071
      #{ab_2.legacy_id},12/12/2021 00:00:00,10/31/2022 00:00:00,Core Induction Programme,3,2600071
      #{ab_3.legacy_id},09/02/2022 00:00:00,11/13/2023 00:00:00,School-based Induction Programme,3,1666461
      #{ab_4.legacy_id},02/01/2023 00:00:00,10/31/2014 00:00:00,Full Induction Programme,3,2600049
      #{ab_5.legacy_id},02/01/2024 00:00:00,10/31/2015 00:00:00,,3,2600049
    CSV
  end

  let(:cutoff_csv_data) do
    <<~CSV
      dqt_id
      f4837bce-28ae-46d0-aae7-d49f1d8f62e3
    CSV
  end

  let(:sample_csv) { CSV.parse(sample_csv_data, headers: true) }
  let(:sample_cutoff_csv) { CSV.parse(cutoff_csv_data, headers: true) }

  subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

  it 'converts csv rows to Row objects when initialized' do
    expect(subject.rows).to all(be_a(AppropriateBodies::Importers::InductionPeriodImporter::Row))
  end

  it 'converts all rows' do
    expect(subject.rows.size).to eql(5)
  end

  describe 'mapping induction programmes' do
    it 'converts names to codes properly' do
      mappings = {
        subject.rows.find { |r| r.legacy_appropriate_body_id == ab_1.legacy_id } => 'pre_september_2021',
        subject.rows.find { |r| r.legacy_appropriate_body_id == ab_2.legacy_id } => 'cip',
        subject.rows.find { |r| r.legacy_appropriate_body_id == ab_3.legacy_id } => 'diy',
        subject.rows.find { |r| r.legacy_appropriate_body_id == ab_4.legacy_id } => 'fip',
        subject.rows.find { |r| r.legacy_appropriate_body_id == ab_5.legacy_id } => 'unknown'
      }
      mappings.each do |row, expected_induction_programme|
        expect(row.to_hash.fetch(:induction_programme)).to eql(expected_induction_programme)
      end
    end
  end

  describe 'number of terms' do
    context 'when number_of_terms is present and finished_on is blank' do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,,,3,2600071
        CSV
      end

      it 'sets the number_of_terms to nil' do
        row_data = subject.periods_as_hashes_by_trn['2600071'].first
        expect(row_data.fetch(:started_on)).to eql(Date.new(2012, 1, 1))
        expect(row_data.fetch(:number_of_terms)).to be_nil
      end
    end
  end

  describe 'finished_on' do
    context 'when started_on and finished_on are the same day' do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,01/01/2012 00:00:00,,3,2600071
          025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2021 00:00:00,,,3,2600071
        CSV
      end

      it 'bumps the finish date by one day' do
        row_data = subject.periods_as_hashes_by_trn['2600071'].first
        expect(row_data.fetch(:started_on)).to eql(Date.new(2012, 1, 1))
        expect(row_data.fetch(:finished_on)).to eql(Date.new(2012, 1, 2))
      end
    end
  end

  describe 'cutoff dates for old appropriate bodies' do
    context 'when the appropriate body ID appears in the cutoff list' do
      let(:cutoff_csv_data) do
        <<~CSV
          dqt_id
          #{ab_1.legacy_id}
        CSV
      end

      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          #{ab_1.legacy_id},01/01/2019 00:00:00,10/31/2024 00:00:00,Core Induction Programme,3,2600071
          #{ab_1.legacy_id},12/12/2020 00:00:00,,Core Induction Programme,3,2600072
          #{ab_1.legacy_id},09/05/2024 00:00:00,,Core Induction Programme,3,2600073
          #{ab_2.legacy_id},01/01/2019 00:00:00,10/31/2024 00:00:00,Core Induction Programme,3,2600074
        CSV
      end

      context 'when the finish date is later than the cutoff date' do
        it 'cuts off the induction period that appears in the cutoff list on 2024-08-31' do
          row_data = subject.periods_as_hashes_by_trn['2600071'].first
          expect(row_data.fetch(:finished_on)).to eql(Date.new(2024, 8, 31))
        end
      end

      context 'when the finish date is null' do
        it 'cuts off the induction period that appears in the cutoff list on 2024-08-31' do
          row_data = subject.periods_as_hashes_by_trn['2600072'].first
          expect(row_data.fetch(:finished_on)).to eql(Date.new(2024, 8, 31))
        end
      end

      context 'when the start date is later than the cutoff date' do
        it 'it sets the finish date to one day later than the start date' do
          row_data = subject.periods_as_hashes_by_trn['2600073'].first
          expect(row_data.fetch(:started_on)).to eql(Date.new(2024, 9, 5))
          expect(row_data.fetch(:finished_on)).to eql(Date.new(2024, 9, 6))
        end
      end

      context 'when the id is not in the cutoff list' do
        it 'leaves the dates untouched' do
          row_data = subject.periods_as_hashes_by_trn['2600074'].first
          expect(row_data.fetch(:started_on)).to eql(Date.new(2019, 1, 1))
          expect(row_data.fetch(:finished_on)).to eql(Date.new(2024, 10, 31))
        end
      end
    end
  end

  describe 'rebuilding periods' do
    context 'when an ECT has one induction period with one AB' do
      let(:sample_csv_data) do
        <<~CSV
          appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
          025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,,,3,2600071
        CSV
      end

      subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

      it 'contains the original row untouched' do
        expect(subject.periods_as_hashes_by_trn).to eql(
          {
            '2600071' => [
              AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                started_on: Date.new(2012, 1, 1),
                finished_on: nil,
                induction_programme: nil,
                legacy_appropriate_body_id: ab_1.legacy_id,
                trn: '2600071',
                number_of_terms: 3,
                notes: []
              ).to_hash
            ]
          }
        )
      end
    end

    context 'when an ECT has two induction periods that have the same programme type with one AB' do
      context 'and the first period ends after the second period has started' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,3,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,3,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2021 00:00:00,,Full Induction Programme,,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'combines the two periods so the new period has the earliest start date and the latest finish date' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 4, 4),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 3,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 2, 2),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 0,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end

      context 'and the first period has an end date and terms but the second does not' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,3,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,,Full Induction Programme,,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'it keeps the finished (first) period' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 3, 3),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 3,
                  notes: []
                ).to_hash,
              ]
            }
          )
        end
      end

      context 'and the second period has an end date and terms but the first does not' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,,Full Induction Programme,,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,3,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'it keeps the finished (second) period' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 3, 3),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 3,
                  notes: []
                ).to_hash,
              ]
            }
          )
        end
      end

      context 'and the second period ends after the first period has started' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,3,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,4,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2021 00:00:00,,Full Induction Programme,,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'combines the two periods so the new period has the earliest start date and the latest finish date' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 4, 4),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 1, 1),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 0
                ).to_hash
              ]
            }
          )
        end

        it 'keeps the higher number of terms' do
          number_of_terms = subject.periods_as_hashes_by_trn.dig('2600071', 0, :number_of_terms)

          expect(number_of_terms).to be(4)
        end
      end

      context 'and the first period contains the second' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,2,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,3,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2021 00:00:00,,Full Induction Programme,3,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'keeps the dates from the first' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 4, 4),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 3,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 2, 2),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 3,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end

      context 'and the second period contains the first' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,1,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2012 00:00:00,04/04/2012 00:00:00,Full Induction Programme,4,2600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,01/01/2021 00:00:00,,Full induction programme,0,2600071
          CSV
        end

        subject { AppropriateBodies::Importers::InductionPeriodImporter.new(nil, nil, csv: sample_csv, cutoff_csv: sample_cutoff_csv) }

        it 'only the second is kept' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '2600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 4, 4),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 1, 1),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 0,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end
    end

    context 'when an ECT has two induction periods that have different programme types with one AB' do
      xspecify 'when one contains the other'

      context 'when the periods do not overlap' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            #{ab_2.legacy_id},01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,4,3600071
            #{ab_2.legacy_id},03/03/2012 00:00:00,05/05/2012 00:00:00,Core Induction Programme,2,3600071
            #{ab_2.legacy_id},03/03/2021 00:00:00,,Full Induction Programme,2,3600071
          CSV
        end

        it 'both are kept' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '3600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 3, 3),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4,
                  notes: []
                ).to_hash,
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 3, 3),
                  finished_on: Date.new(2012, 5, 5),
                  induction_programme: 'Core Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 3, 3),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end

      context 'when the periods overlap' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            #{ab_2.legacy_id},01/01/2012 00:00:00,05/05/2012 00:00:00,Full Induction Programme,4,3600071
            #{ab_2.legacy_id},04/04/2012 00:00:00,06/06/2012 00:00:00,Core Induction Programme,2,3600071
            #{ab_2.legacy_id},03/03/2021 00:00:00,,Full Induction Programme,2,3600071
          CSV
        end

        it 'the earlier one is curtailed so it does not clash with the later one' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '3600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 4, 4),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4,
                  notes: []
                ).to_hash,
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 4, 4),
                  finished_on: Date.new(2012, 6, 6),
                  induction_programme: 'Core Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 3, 3),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end
    end

    context 'when an ECT has two induction period with different ABs' do
      xspecify 'when one contains the other'

      context 'when the periods do not overlap' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            1ddf3e82-c1ae-e311-b8ed-005056822391,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,4,3600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,03/03/2012 00:00:00,05/05/2012 00:00:00,Full Induction Programme,2,3600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,03/03/2021 00:00:00,,Full Induction Programme,2,3600071
          CSV
        end

        it 'both are kept' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '3600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 3, 3),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4,
                  notes: []
                ).to_hash,
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 3, 3),
                  finished_on: Date.new(2012, 5, 5),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 3, 3),
                  finished_on: nil,
                  induction_programme: 'Full Induction Prorgramme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 2,
                  notes: []
                ).to_hash
              ]
            }
          )
        end
      end

      context 'when the periods overlap' do
        let(:sample_csv_data) do
          <<~CSV
            appropriate_body_id,started_on,finished_on,induction_programme_choice,number_of_terms,trn
            1ddf3e82-c1ae-e311-b8ed-005056822391,01/01/2012 00:00:00,03/03/2012 00:00:00,Full Induction Programme,1,3600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2012 00:00:00,05/05/2012 00:00:00,Full Induction Programme,4,3600071
            025e61e7-ec32-eb11-a813-000d3a228dfc,02/02/2021 00:00:00,,Full Induction Programme,4,3600071
          CSV
        end

        it 'both are kept but the earlier one is shortened to prevent overlap with the second' do
          expect(subject.periods_as_hashes_by_trn).to eql(
            {
              '3600071' => [
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 1, 1),
                  finished_on: Date.new(2012, 2, 2),
                  induction_programme: 'Full Induction Progamme',
                  legacy_appropriate_body_id: ab_2.legacy_id,
                  trn: '2600071',
                  number_of_terms: 1
                ).to_hash,
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2012, 2, 2),
                  finished_on: Date.new(2012, 5, 5),
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4
                ).to_hash,
                # unrelated ongoing record so induction periods are included by the import
                AppropriateBodies::Importers::InductionPeriodImporter::Row.new(
                  started_on: Date.new(2021, 2, 2),
                  finished_on: nil,
                  induction_programme: 'Full Induction Programme',
                  legacy_appropriate_body_id: ab_1.legacy_id,
                  trn: '2600071',
                  number_of_terms: 4
                ).to_hash
              ]
            }
          )
        end
      end
    end
  end
end
