describe Teachers::Name do
  subject(:service) { Teachers::Name.new(teacher) }

  describe '#full_name' do
    context 'when teacher is missing' do
      let(:teacher) { nil }

      it 'returns nil' do
        expect(service.full_name).to be_nil
      end
    end

    context 'when a corrected_name is set' do
      let(:teacher) { FactoryBot.build(:teacher, :with_corrected_name) }

      it 'returns the corrected name' do
        expect(teacher.corrected_name).to be_present
        expect(service.full_name).to eql(teacher.corrected_name)
      end
    end

    context 'when no corrected_name is set' do
      let(:teacher) { FactoryBot.build(:teacher, corrected_name: nil) }

      it 'returns the first name followed by the last name' do
        expect(service.full_name).to eql(%(#{teacher.trs_first_name} #{teacher.trs_last_name}))
      end
    end

    context 'when the corrected_name is an empty string' do
      let(:teacher) { FactoryBot.build(:teacher, corrected_name: "") }

      it 'returns the first name followed by the last name' do
        expect(service.full_name).to eql(%(#{teacher.trs_first_name} #{teacher.trs_last_name}))
      end
    end

    describe 'when both names are missing names in TRS' do
      subject { service.full_name }

      let(:teacher) { FactoryBot.build(:teacher, **names) }

      context 'when both names are nil' do
        let(:names) { { trs_first_name: nil, trs_last_name: nil } }

        it('returns Unknown') { is_expected.to eql('Unknown') }
      end

      context 'when both names are .' do
        let(:names) { { trs_first_name: '.', trs_last_name: '.' } }

        it('returns Unknown') { is_expected.to eql('Unknown') }
      end

      context 'when names are a mix of missing values' do
        let(:names) { { trs_first_name: nil, trs_last_name: '' } }

        it('returns Unknown') { is_expected.to eql('Unknown') }
      end
    end
  end

  describe '#full_name_in_trs' do
    let(:teacher) { FactoryBot.build(:teacher, trs_first_name: 'Diana', trs_last_name: 'Rigg') }

    it 'returns the first name followed by the last name' do
      expect(service.full_name_in_trs).to eql(%(#{teacher.trs_first_name} #{teacher.trs_last_name}))
    end

    context 'when the corrected_name is present' do
      let(:teacher) { FactoryBot.build(:teacher, trs_first_name: 'Diana', trs_last_name: 'Rigg', corrected_name: 'Diana Elizabeth Rigg') }

      it 'is ignored' do
        expect(service.full_name_in_trs).to eql(%(#{teacher.trs_first_name} #{teacher.trs_last_name}))
      end
    end

    describe 'partial names in TRS' do
      subject { service.full_name_in_trs }

      let(:teacher) { FactoryBot.build(:teacher, **names) }

      context 'when the first name is nil' do
        let(:names) { { trs_first_name: nil, trs_last_name: 'Rigg' } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_last_name) }
      end

      context 'when the first name is blank' do
        let(:names) { { trs_first_name: '', trs_last_name: 'Rigg' } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_last_name) }
      end

      context 'when the first name is .' do
        let(:names) { { trs_first_name: '.', trs_last_name: 'Rigg' } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_last_name) }
      end

      context 'when the last name is nil' do
        let(:names) { { trs_first_name: 'Diana', trs_last_name: nil } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_first_name) }
      end

      context 'when the last name is blank' do
        let(:names) { { trs_first_name: 'Diana', trs_last_name: '' } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_first_name) }
      end

      context 'when the last name is .' do
        let(:names) { { trs_first_name: 'Diana', trs_last_name: '.' } }

        it('returns only the last name') { is_expected.to eql(teacher.trs_first_name) }
      end
    end
  end
end
