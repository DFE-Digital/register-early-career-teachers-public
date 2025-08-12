RSpec.describe 'ECT summary' do
  let(:ect) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:school) { FactoryBot.create(:school) }

  describe '#show' do
    context 'when signed in as school user' do
      before do
        sign_in_as(:school_user, school:)
        get("/school/ects/#{ect.id}")
      end

      it { expect(response).to be_successful }
    end

    describe 'finding the ECT at school period' do
      subject { response }

      context 'when signed in as user from the same school' do
        before do
          sign_in_as(:school_user, school:)
          get("/school/ects/#{ect.id}")
        end

        it { is_expected.to be_successful }
      end

      context 'when signed in as user from another school' do
        before do
          sign_in_as(:school_user, school: FactoryBot.create(:school))
          get("/school/ects/#{ect.id}")
        end

        it { is_expected.to be_not_found }
      end
    end
  end
end
