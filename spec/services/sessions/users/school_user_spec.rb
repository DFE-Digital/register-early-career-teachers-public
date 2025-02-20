require_relative 'session_user_context'

RSpec.describe Sessions::Users::SchoolUser do
  let(:email) { 'school_user@email.com' }
  let(:last_active_at) { 4.minutes.ago }
  let(:name) { 'Christopher Lee' }
  let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
  let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
  let(:school) { FactoryBot.create(:school) }

  subject(:school_user) do
    described_class.new(email:, name:, school_urn: school.urn, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, last_active_at:)
  end

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, school_urn: school.urn, dfe_sign_in_organisation_id:, dfe_sign_in_user_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :dfe_sign_in' do
      expect(described_class::PROVIDER).to eql(:dfe_sign_in)
    end
  end

  describe '.USER_TYPE' do
    it 'returns :school_user' do
      expect(described_class::USER_TYPE).to eql(:school_user)
    end
  end

  context 'initialisation' do
    describe "when there is no school with the given urn" do
      let(:unknown_urn) { 'A123456' }
      subject do
        described_class.new(email:,
                            name:,
                            school_urn: unknown_urn,
                            dfe_sign_in_organisation_id:,
                            dfe_sign_in_user_id:,
                            last_active_at:)
      end

      it 'fails with an UnknownOrganisationURN error' do
        expect { subject }.to raise_error(described_class::UnknownOrganisationURN, unknown_urn)
      end
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(school_user).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns true' do
      expect(school_user.dfe_sign_in_authorisable?).to be_truthy
    end
  end

  describe '#dfe_sign_in_organisation_id' do
    it 'returns the id of the organisation of the user in DfE SignIn' do
      expect(school_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe '#dfe_sign_in_user_id' do
    it 'returns the id of the user in DfE SignIn' do
      expect(school_user.dfe_sign_in_user_id).to eql(dfe_sign_in_user_id)
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(school_user).not_to be_dfe_user
    end
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(school_user.event_author_params).to eql({
        author_email: school_user.email,
        author_name: school_user.name,
        author_type: :school_user
      })
    end
  end

  describe '#name' do
    it 'returns the full name of the user' do
      expect(school_user.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns the name of the school associated to the user' do
      expect(school_user.organisation_name).to eq(school.name)
    end
  end

  describe '#school' do
    it 'returns the school of the user' do
      expect(school_user.school).to eql(school)
    end
  end

  describe '#school_user?' do
    it 'returns true' do
      expect(school_user).to be_school_user
    end
  end

  describe '#school_urn' do
    it 'returns the urn of the school of the user' do
      expect(school_user.school_urn).to eql(school.urn)
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(school_user.to_h).to eql({
        'type' => 'Sessions::Users::SchoolUser',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'school_urn' => school.urn,
        'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id,
        'dfe_sign_in_user_id' => dfe_sign_in_user_id
      })
    end
  end

  describe '#user_type' do
    it('is :school_user') { expect(school_user.user_type).to be(:school_user) }
  end

  describe '#user' do
    it 'returns nil' do
      expect(school_user.user).to be_nil
    end
  end
end
