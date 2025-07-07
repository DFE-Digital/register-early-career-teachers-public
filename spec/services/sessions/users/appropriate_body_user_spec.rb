require_relative 'session_user_context'

RSpec.describe Sessions::Users::AppropriateBodyUser do
  subject(:appropriate_body_user) do
    described_class.new(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, last_active_at:)
  end

  let(:email) { 'appropriate_body_user@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
  let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
  let(:last_active_at) { 4.minutes.ago }
  let!(:appropriate_body) { create(:appropriate_body, dfe_sign_in_organisation_id:) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :dfe_sign_in' do
      expect(described_class::PROVIDER).to be(:dfe_sign_in)
    end
  end

  describe '.USER_TYPE' do
    it 'returns :appropriate_body_user' do
      expect(described_class::USER_TYPE).to be(:appropriate_body_user)
    end
  end

  context 'initialisation' do
    describe "when an appropriate body can't be found from the given dfe_sign_in_organisation_id" do
      subject do
        described_class.new(email:,
                            name:,
                            dfe_sign_in_organisation_id: unknown_organisation_id,
                            dfe_sign_in_user_id:,
                            last_active_at:)
      end

      let(:unknown_organisation_id) { SecureRandom.uuid }

      it 'fails with an UnknownOrganisationId error' do
        expect { subject }.to raise_error(described_class::UnknownOrganisationId, unknown_organisation_id)
      end
    end
  end

  describe '#appropriate_body' do
    it 'returns the appropriate_body associated to the persona' do
      expect(appropriate_body_user.appropriate_body).to eql(appropriate_body)
    end
  end

  describe '#appropriate_body_id' do
    it 'returns the id of the appropriate body of the user' do
      expect(appropriate_body_user.appropriate_body_id).to eql(appropriate_body.id)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns true' do
      expect(appropriate_body_user).to be_appropriate_body_user
    end
  end

  describe '#dfe_sign_in_organisation_id' do
    it 'returns the id of the organisation of the user in DfE SignIn' do
      expect(appropriate_body_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
    end
  end

  describe '#dfe_sign_in_user_id' do
    it 'returns the id of the user in DfE SignIn' do
      expect(appropriate_body_user.dfe_sign_in_user_id).to eql(dfe_sign_in_user_id)
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(appropriate_body_user).not_to be_dfe_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns true' do
      expect(appropriate_body_user.dfe_sign_in_authorisable?).to be_truthy
    end
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(appropriate_body_user.event_author_params).to eql({
        author_email: appropriate_body_user.email,
        author_name: appropriate_body_user.name,
        author_type: :appropriate_body_user
      })
    end
  end

  describe '#name' do
    it 'returns the full name of the appropriate body user' do
      expect(appropriate_body_user.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns the name of the appropriate body associated to the user' do
      expect(appropriate_body_user.organisation_name).to eq(appropriate_body.name)
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(appropriate_body_user).not_to be_school_user
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(appropriate_body_user.to_h).to eql({
        'type' => 'Sessions::Users::AppropriateBodyUser',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id,
        'dfe_sign_in_user_id' => dfe_sign_in_user_id
      })
    end
  end

  describe '#user_type' do
    it('is :appropriate_body_user') { expect(appropriate_body_user.user_type).to be(:appropriate_body_user) }
  end

  describe '#user' do
    it 'returns nil' do
      expect(appropriate_body_user.user).to be_nil
    end
  end
end
