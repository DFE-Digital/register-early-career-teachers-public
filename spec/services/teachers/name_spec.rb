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
  end
end
