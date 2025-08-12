RSpec.describe 'ECT summary' do
  let(:ect) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:school) { FactoryBot.create(:school) }

  context 'when signed in as school user' do
    before do
      sign_in_as(:school_user, school:)
      get("/school/ects/#{ect.id}")
    end

    it { expect(response).to be_successful }
  end
end
