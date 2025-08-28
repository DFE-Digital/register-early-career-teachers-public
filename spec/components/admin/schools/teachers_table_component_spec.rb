RSpec.describe Admin::Schools::TeachersTableComponent, type: :component do
  let(:school) { FactoryBot.create(:school) }
  let(:component) { described_class.new(school:) }

  describe '#teachers_with_roles' do
    context 'when school has no teachers' do
      it 'returns empty array' do
        expect(component.teachers_with_roles).to eq([])
      end
    end

    context 'when school has ECT and mentor teachers' do
      let(:ect_teacher) { FactoryBot.create(:teacher, trs_first_name: 'John', trs_last_name: 'Doe') }
      let(:mentor_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Jane', trs_last_name: 'Smith') }
      let(:both_roles_teacher) { FactoryBot.create(:teacher, trs_first_name: 'Bob', trs_last_name: 'Wilson') }

      before do
        # Create ECT at school period
        FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher: ect_teacher, started_on: 1.year.ago)

        # Create mentor at school period
        FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: mentor_teacher, started_on: 6.months.ago)

        # Create teacher with both roles
        FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher: both_roles_teacher, started_on: 8.months.ago)
        FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: both_roles_teacher, started_on: 4.months.ago)
      end

      it 'returns all teachers with their roles' do
        result = component.teachers_with_roles

        expect(result.length).to eq(3)
        expect(result.map { |data| data[:teacher] }).to contain_exactly(ect_teacher, mentor_teacher, both_roles_teacher)
      end

      it 'includes correct teacher data' do
        result = component.teachers_with_roles

        ect_data = result.find { |data| data[:teacher] == ect_teacher }
        expect(ect_data[:teacher]).to eq(ect_teacher)

        mentor_data = result.find { |data| data[:teacher] == mentor_teacher }
        expect(mentor_data[:teacher]).to eq(mentor_teacher)

        both_data = result.find { |data| data[:teacher] == both_roles_teacher }
        expect(both_data[:teacher]).to eq(both_roles_teacher)
      end
    end
  end

  describe '#latest_contract_period' do
    it 'returns contract period when available' do
      teacher_data = { latest_contract_period: 2024 }
      expect(component.latest_contract_period(teacher_data)).to eq(2024)
    end

    it 'returns contract period value directly' do
      teacher_data = { latest_contract_period: Date.current.year }
      expect(component.latest_contract_period(teacher_data)).to eq(Date.current.year)
    end
  end

  describe 'rendering' do
    context 'when school has no teachers' do
      it 'displays no teachers message' do
        render_inline(component)

        expect(rendered_content).to have_css('p', text: 'No teachers found at this school.')
        expect(rendered_content).not_to have_css('table.govuk-table')
      end
    end

    context 'when school has teachers' do
      let(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }

      before do
        FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher:)
      end

      it 'displays teachers table with correct headers' do
        render_inline(component)

        expect(rendered_content).to have_css('table.govuk-table')
        expect(rendered_content).to have_css('th', text: 'Name')
        expect(rendered_content).to have_css('th', text: 'TRN')
        expect(rendered_content).to have_css('th', text: 'Type')
        expect(rendered_content).to have_css('th', text: 'Contract period')
      end

      it 'displays teacher information' do
        render_inline(component)

        expect(rendered_content).to have_css('td', text: '1234567')
        expect(rendered_content).to have_css('td', text: 'ECT')
        expect(rendered_content).to have_css('td', text: Date.current.year.to_s)
      end
    end
  end
end
