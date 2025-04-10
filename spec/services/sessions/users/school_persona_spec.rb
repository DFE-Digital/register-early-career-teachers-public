require_relative 'session_user_context'

RSpec.describe Sessions::Users::SchoolPersona do
  subject(:school_persona) { described_class.new(email:, name:, school_urn: school.urn, last_active_at:) }

  let(:email) { 'school_persona@email.com' }
  let(:last_active_at) { 4.minutes.ago }
  let(:name) { 'Christopher Lee' }
  let(:school) { FactoryBot.create(:school) }

  it_behaves_like 'a session user' do
    let(:user_props) { { email:, name:, school_urn: school.urn } }
  end

  describe '.PROVIDER' do
    it 'returns :persona' do
      expect(described_class::PROVIDER).to be(:persona)
    end
  end

  describe '.USER_TYPE' do
    it 'returns :school_user' do
      expect(described_class::USER_TYPE).to be(:school_user)
    end
  end

  context 'initialisation' do
    describe "when personas are disabled" do
      before { allow(Rails.application.config).to receive(:enable_personas).and_return(false) }

      it 'fails with a DfEPersonaDisabledError' do
        expect { subject }.to raise_error(described_class::SchoolPersonaDisabledError)
      end
    end

    describe "when there is no school with the given urn" do
      subject(:school_persona) { described_class.new(email:, name:, school_urn: unknown_urn, last_active_at:) }

      let(:unknown_urn) { 'A123456' }

      it 'fails with an UnknownSchoolURN error' do
        expect { subject }.to raise_error(described_class::UnknownSchoolURN, unknown_urn)
      end
    end
  end

  describe '#appropriate_body_user?' do
    it 'returns false' do
      expect(school_persona).not_to be_appropriate_body_user
    end
  end

  describe '#dfe_sign_in_authorisable?' do
    it 'returns false' do
      expect(school_persona.dfe_sign_in_authorisable?).to be_falsey
    end
  end

  describe '#dfe_user?' do
    it 'returns false' do
      expect(school_persona).not_to be_dfe_user
    end
  end

  describe '#event_author_params' do
    it 'returns a hash with the attributes needed to record an event' do
      expect(school_persona.event_author_params).to eql({
        author_email: school_persona.email,
        author_name: school_persona.name,
        author_type: :school_user
      })
    end
  end

  describe '#name' do
    it 'returns the full name of the user' do
      expect(school_persona.name).to eql(name)
    end
  end

  describe '#organisation_name' do
    it 'returns the name of the school associated to the user' do
      expect(school_persona.organisation_name).to eq(school.name)
    end
  end

  describe '#school' do
    it 'returns the school of the user' do
      expect(school_persona.school).to eql(school)
    end
  end

  describe '#school_urn' do
    it 'returns the urn of the school of the user' do
      expect(school_persona.school_urn).to eql(school.urn)
    end
  end

  describe '#school_user?' do
    it 'returns true' do
      expect(school_persona).to be_school_user
    end
  end

  describe '#to_h' do
    it 'returns a hash including only relevant attributes' do
      expect(school_persona.to_h).to eql({
        'type' => 'Sessions::Users::SchoolPersona',
        'email' => email,
        'name' => name,
        'last_active_at' => last_active_at,
        'school_urn' => school.urn
      })
    end
  end

  describe '#user_type' do
    it('is :school_user') { expect(school_persona.user_type).to be(:school_user) }
  end

  describe '#user' do
    it 'returns nil' do
      expect(school_persona.user).to be_nil
    end
  end
end
