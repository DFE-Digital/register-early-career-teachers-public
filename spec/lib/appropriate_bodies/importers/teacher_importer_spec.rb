describe AppropriateBodies::Importers::TeacherImporter do
  let(:sample_data) do
    <<~CSV
      trn,first_name,last_name,extension_length,extension_length_unit,induction_status
      1234567,Faye,Tozer,,,RequiredToComplete
      2345678,Lisa,Scott-Lee,,,InProgress
      3456789,Lee,Latchford-Evans,,,InProgress
    CSV
  end

  let(:wanted_trns) { %w[1234567 2345678] }

  subject { AppropriateBodies::Importers::TeacherImporter.new(nil, wanted_trns, csv: sample_data.lines) }

  it 'converts the wanted rows into AppropriateBodies::Importers::TeacherImporter::Row objects' do
    expect(subject.rows.map(&:trn)).to include(*wanted_trns)
  end

  it 'skips rows that are not wanted' do
    expect(subject.rows.map(&:trn)).not_to include('3456789')
  end

  describe 'extension lengths' do
    let(:sample_data) do
      <<~CSV
        trn,first_name,last_name,extension_length,extension_length_unit,induction_status
        1234567,Faye,Tozer,9,Years,RequiredToComplete
        2345678,Lisa,Scott-Lee,14,Months,InProgress
        3456789,Lee,Latchford-Evans,20,Weeks,InProgress
        4567890,Ian,Watkins,200,Days,InProgress
      CSV
    end

    let(:wanted_trns) { %w[1234567 2345678 3456789 4567890] }

    it 'converts 9 years to be 27.0 terms' do
      expect(subject.rows.find { |r| r.trn == '1234567' }.extension_terms).to eql(27.0)
    end

    it 'converts 14 months to be 4.7 terms' do
      expect(subject.rows.find { |r| r.trn == '2345678' }.extension_terms).to eql(4.7)
    end

    it 'converts 20 weeks to be 1.5 terms' do
      expect(subject.rows.find { |r| r.trn == '3456789' }.extension_terms).to eql(1.5)
    end

    it 'converts 200 days to be 3.1' do
      expect(subject.rows.find { |r| r.trn == '4567890' }.extension_terms).to eql(3.1)
    end
  end
end
