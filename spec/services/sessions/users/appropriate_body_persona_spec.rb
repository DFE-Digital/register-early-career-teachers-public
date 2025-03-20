require_relative 'session_user_context'

RSpec.describe Sessions::Users::AppropriateBodyPersona do
  subject(:appropriate_body_persona) do
    described_class.new(email:, name:, appropriate_body_id:, last_active_at:)
  end

  let(:email) { 'appropriate_body_persona@email.com' }
  let(:name) { 'Christopher Lee' }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:appropriate_body_id) { appropriate_body.id }
  let(:last_active_at) { 4.minutes.ago }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, appropriate_body_id: } }
  end

  describe '.PROVIDER' do
    it 'returns :persona' do
      expect(described_class::PROVIDER).to be(:persona)
    end
  end

  describe '.USER_TYPE' do
    it 'returns :appropriate_body_user' do
      expect(described_class::USER_TYPE).to be(:appropriate_body_user)
    end
  end

  context 'initialisation' do
    describe "when personas are disabled" do
      before { allow(Rails.application.config).to receive(:enable_personas).and_return(false) }

      it 'fails with a DfEPersonaDisabledError' do
        expect { subject }.to raise_error(described_class::AppropriateBodyPersonaDisabledError)
      end
    end

    describe "when an appropriate body can't be found from the given id" do
      let(:appropriate_body_id) { SecureRandom.uuid }

      it 'fails with an UnknownAppropriateBodyId error' do
        expect { subject }.to raise_error(described_class::UnknownAppropriateBodyId, appropriate_body_id)
      end
    end
  end

  describe '#appropriate_body' do
    it 'returns the appropriate_body associated to the persona' do
      expect(appropriate_body_persona.appropriate_body).to eql(appropriate_body)
    end
  end

  describe '#appropriate_body_id' do
    it 'returns the appropriate_body_id of the persona' do
      expect(appropriate_body_persona.appropriate_body_id).to eql(appropriate_body_id)
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns true' do
      expect(appropriate_body_persona).to be_appropriate_body_user
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(appropriate_body_persona).not_to be_dfe_user
    end
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(appropriate_body_persona.event_author_params).to eql({
        author_email: appropriate_body_persona.email,
        author_name: appropriate_body_persona.name,
        author_type: :appropriate_body_user
      })
    end
  end

  describe '#name' do
    it 'returns the name of the appropriate body persona' do
      expect(appropriate_body_persona.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns the name of the appropriate body associated to the user' do
      expect(appropriate_body_persona.organisation_name).to eq(appropriate_body.name)
    end
  end

  describe '#school_user?' do
    it 'returns false' do
      expect(appropriate_body_persona).not_to be_school_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns false' do
      expect(appropriate_body_persona.dfe_sign_in_authorisable?).to be_falsey
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(appropriate_body_persona.to_h).to eql({
        'type' => 'Sessions::Users::AppropriateBodyPersona',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'appropriate_body_id' => appropriate_body_id
      })
    end
  end

  describe '#user_type' do
    it('is :appropriate_body_user') { expect(appropriate_body_persona.user_type).to be(:appropriate_body_user) }
  end

  describe '#user' do
    it 'returns nil' do
      expect(appropriate_body_persona.user).to be_nil
    end
  end
end
