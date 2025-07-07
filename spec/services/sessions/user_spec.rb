RSpec.describe Sessions::User do
  subject(:session_user) { described_class.new(email: 'a@email.com', last_active_at:) }

  let(:last_active_at) { 4.minutes.ago }

  describe '.from_session' do
    subject(:session_user) { described_class.from_session(fake_user_session) }

    context 'when the user session stores no user data' do
      let(:fake_user_session) { {} }

      it 'do not instantiate any Sessions::User' do
        expect(session_user).to be_nil
      end
    end

    context 'when user session stores an appropriate body user' do
      let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
      let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
      let!(:appropriate_body) { create(:appropriate_body, dfe_sign_in_organisation_id:) }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::Users::AppropriateBodyUser',
          'email' => 'ab_user@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id,
          'dfe_sign_in_user_id' => dfe_sign_in_user_id
        }
      end

      it 'instantiates a Sessions::Users::AppropriateBodyUser' do
        expect(session_user).to be_a(Sessions::Users::AppropriateBodyUser)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('ab_user@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.appropriate_body_id).to be(appropriate_body.id)
      end
    end

    context 'when user session stores an appropriate body persona' do
      let(:appropriate_body) { create(:appropriate_body) }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::Users::AppropriateBodyPersona',
          'email' => 'ab_persona@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'appropriate_body_id' => appropriate_body.id
        }
      end

      it 'instantiates a Sessions::Users::AppropriateBodyPersona' do
        expect(session_user).to be_a(Sessions::Users::AppropriateBodyPersona)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('ab_persona@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.appropriate_body_id).to be(appropriate_body.id)
      end
    end

    context 'when user session stores an existing db dfe user' do
      let!(:dfe_user) { create(:user, :admin, name: 'Christopher Lee', email: 'dfe_user@example.com') }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::Users::DfEUser',
          'email' => 'dfe_user@example.com',
          'last_active_at' => last_active_at
        }
      end

      it 'instantiates a Sessions::Users::DfEUser' do
        expect(session_user).to be_a(Sessions::Users::DfEUser)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('dfe_user@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
      end
    end

    context 'when user session stores a dfe persona' do
      let!(:dfe_user) { create(:user, :admin, name: 'Christopher Lee', email: 'dfe_persona@example.com') }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::Users::DfEPersona',
          'email' => 'dfe_persona@example.com',
          'last_active_at' => last_active_at
        }
      end

      it 'instantiates a Sessions::Users::DfEPersona' do
        expect(session_user).to be_a(Sessions::Users::DfEPersona)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('dfe_persona@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
      end
    end

    context 'when user session stores a school user' do
      let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
      let(:dfe_sign_in_user_id) { Faker::Internet.uuid }
      let(:school_urn) { create(:school).urn }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::Users::SchoolUser',
          'email' => 'school_user@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'school_urn' => school_urn,
          'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id,
          'dfe_sign_in_user_id' => dfe_sign_in_user_id
        }
      end

      it 'instantiates a Sessions::Users::SchoolUser' do
        expect(session_user).to be_a(Sessions::Users::SchoolUser)
        expect(session_user.email).to eql('school_user@example.com')
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.school_urn).to eql(school_urn)
        expect(session_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
      end
    end
  end
end
