RSpec.describe Teachers::Role do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:other_school) { FactoryBot.create(:school) }

  describe '#initialize' do
    it 'accepts a teacher parameter' do
      role = described_class.new(teacher:)
      expect(role.teacher).to eq(teacher)
      expect(role.school).to be_nil
    end

    it 'accepts teacher and school parameters' do
      role = described_class.new(teacher:, school:)
      expect(role.teacher).to eq(teacher)
      expect(role.school).to eq(school)
    end
  end

  describe '#roles' do
    context 'when no school is specified' do
      let(:role_service) { described_class.new(teacher:) }

      context 'when teacher has ongoing ECT period at any school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
        end

        it 'returns ECT role' do
          expect(role_service.roles).to eq(%w[ECT])
        end
      end

      context 'when teacher has inactive ECT period at any school' do
        before do
          FactoryBot.create(
            :ect_at_school_period,
            teacher:,
            school:,
            started_on: 2.months.ago,
            finished_on: 1.month.ago
          )
        end

        it 'returns ECT (Inactive) role' do
          expect(role_service.roles).to eq(['ECT (Inactive)'])
        end
      end

      context 'when teacher has ongoing mentor period at any school' do
        before do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:)
        end

        it 'returns Mentor role' do
          expect(role_service.roles).to eq(%w[Mentor])
        end
      end

      context 'when teacher has inactive mentor period at any school' do
        before do
          FactoryBot.create(:mentor_at_school_period, teacher:, school:, finished_on: 1.month.ago)
        end

        it 'returns Mentor (Inactive) role' do
          expect(role_service.roles).to eq(['Mentor (Inactive)'])
        end
      end

      context 'when teacher has both ECT and mentor roles' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns both roles' do
          expect(role_service.roles).to contain_exactly('ECT', 'Mentor')
        end
      end

      context 'when teacher has no periods' do
        it 'returns empty array' do
          expect(role_service.roles).to eq([])
        end
      end
    end

    context 'when school is specified' do
      let(:role_service) { described_class.new(teacher:, school:) }

      context 'when teacher has ongoing ECT period at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          # Add mentor period at other school to test filtering
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns ECT role for the specified school only' do
          expect(role_service.roles).to eq(%w[ECT])
        end
      end

      context 'when teacher has ECT period at other school but not specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns empty array' do
          expect(role_service.roles).to eq([])
        end
      end

      context 'when teacher has inactive ECT period at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: 2.years.ago, finished_on: 1.month.ago)
          # Create ongoing period at other school that starts after the inactive period finished
          FactoryBot.create(:ect_at_school_period, teacher:, school: other_school, started_on: 2.weeks.ago, finished_on: nil)
        end

        it 'returns ECT (Inactive) role for the specified school' do
          expect(role_service.roles).to eq(['ECT (Inactive)'])
        end
      end

      context 'when teacher has ongoing mentor period at the specified school' do
        before do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns Mentor role for the specified school only' do
          expect(role_service.roles).to eq(%w[Mentor])
        end
      end

      context 'when teacher has mentor period at other school but not specified school' do
        before do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns empty array' do
          expect(role_service.roles).to eq([])
        end
      end

      context 'when teacher has inactive mentor period at the specified school' do
        before do
          FactoryBot.create(:mentor_at_school_period, teacher:, school:, finished_on: 1.month.ago)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns Mentor (Inactive) role for the specified school' do
          expect(role_service.roles).to eq(['Mentor (Inactive)'])
        end
      end

      context 'when teacher has both ECT and mentor roles at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:)
          # Add periods at other school with different dates to ensure we're filtering correctly
          FactoryBot.create(:ect_at_school_period, teacher:, school: other_school, started_on: 3.years.ago, finished_on: 2.years.ago)
        end

        it 'returns both roles for the specified school' do
          expect(role_service.roles).to contain_exactly('ECT', 'Mentor')
        end
      end

      context 'when teacher has mixed active/inactive roles at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, teacher:, school:, finished_on: 1.month.ago)
        end

        it 'returns active ECT and inactive Mentor roles' do
          expect(role_service.roles).to contain_exactly('ECT', 'Mentor (Inactive)')
        end
      end

      context 'when teacher has no periods at the specified school' do
        before do
          # Add periods at other schools to ensure we're filtering correctly
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: other_school)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns empty array' do
          expect(role_service.roles).to eq([])
        end
      end
    end
  end

  describe '#to_s' do
    context 'when no school is specified' do
      let(:role_service) { described_class.new(teacher:) }

      context 'with single role' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
        end

        it 'returns the role as string' do
          expect(role_service.to_s).to eq('ECT')
        end
      end

      context 'with multiple roles' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'joins roles with ampersand' do
          expect(role_service.to_s).to eq('ECT & Mentor')
        end
      end

      context 'with no roles' do
        it 'returns empty string' do
          expect(role_service.to_s).to eq('')
        end
      end
    end

    context 'when school is specified' do
      let(:role_service) { described_class.new(teacher:, school:) }

      context 'with roles at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
          FactoryBot.create(:mentor_at_school_period, teacher:, school:, finished_on: 1.month.ago)
        end

        it 'returns roles for the specified school only' do
          expect(role_service.to_s).to eq('ECT & Mentor (Inactive)')
        end
      end

      context 'with no roles at the specified school' do
        before do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: other_school)
        end

        it 'returns empty string' do
          expect(role_service.to_s).to eq('')
        end
      end
    end
  end

  describe 'backward compatibility' do
    context 'existing usage without school parameter' do
      let(:role_service) { described_class.new(teacher:) }

      before do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:)
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school: other_school)
      end

      it 'works as before, checking all schools' do
        expect(role_service.roles).to contain_exactly('ECT', 'Mentor')
        expect(role_service.to_s).to eq('ECT & Mentor')
      end
    end
  end
end
