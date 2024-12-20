RSpec.describe Sessions::SessionUser do
  let(:last_active_at) { 4.minutes.ago }

  subject(:session_user) { described_class.new(email: 'a@email.com', last_active_at:) }

  describe '.from_session' do
    subject(:session_user) { described_class.from_session(fake_user_session) }

    context 'when user session stores an appropriate body user' do
      let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
      let!(:appropriate_body) { FactoryBot.create(:appropriate_body, dfe_sign_in_organisation_id:) }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::AppropriateBodyUser',
          'email' => 'ab_user@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id
        }
      end

      it 'instantiates a Sessions::AppropriateBodyUser' do
        expect(session_user).to be_a(Sessions::AppropriateBodyUser)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('ab_user@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.appropriate_body_id).to be(appropriate_body.id)
      end
    end

    context 'when user session stores an appropriate body persona' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::AppropriateBodyPersona',
          'email' => 'ab_persona@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'appropriate_body_id' => appropriate_body.id
        }
      end

      it 'instantiates a Sessions::AppropriateBodyPersona' do
        expect(session_user).to be_a(Sessions::AppropriateBodyPersona)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('ab_persona@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.appropriate_body_id).to be(appropriate_body.id)
      end
    end

    context 'when user session stores an existing db dfe user' do
      let!(:dfe_user) { FactoryBot.create(:user, :admin, name: 'Christopher Lee', email: 'dfe_user@example.com') }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::DfEUser',
          'email' => 'dfe_user@example.com',
          'last_active_at' => last_active_at
        }
      end

      it 'instantiates a Sessions::DfEUser' do
        expect(session_user).to be_a(Sessions::DfEUser)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('dfe_user@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
      end
    end

    context 'when user session stores a dfe persona' do
      let!(:dfe_user) { FactoryBot.create(:user, :admin, name: 'Christopher Lee', email: 'dfe_persona@example.com') }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::DfEPersona',
          'email' => 'dfe_persona@example.com',
          'last_active_at' => last_active_at
        }
      end

      it 'instantiates a Sessions::DfEPersona' do
        expect(session_user).to be_a(Sessions::DfEPersona)
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.email).to eql('dfe_persona@example.com')
        expect(session_user.last_active_at).to eql(last_active_at)
      end
    end

    context 'when user session stores a school user' do
      let(:dfe_sign_in_organisation_id) { Faker::Internet.uuid }
      let(:school_urn) { FactoryBot.create(:school).urn }
      let(:fake_user_session) do
        {
          'type' => 'Sessions::SchoolUser',
          'email' => 'school_user@example.com',
          'name' => 'Christopher Lee',
          'last_active_at' => last_active_at,
          'school_urn' => school_urn,
          'dfe_sign_in_organisation_id' => dfe_sign_in_organisation_id
        }
      end

      it 'instantiates a Sessions::SchoolUser' do
        expect(session_user).to be_a(Sessions::SchoolUser)
        expect(session_user.email).to eql('school_user@example.com')
        expect(session_user.name).to eql('Christopher Lee')
        expect(session_user.last_active_at).to eql(last_active_at)
        expect(session_user.school_urn).to eql(school_urn)
        expect(session_user.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
      end
    end
  end
end
