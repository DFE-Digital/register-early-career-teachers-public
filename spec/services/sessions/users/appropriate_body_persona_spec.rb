RSpec.describe Sessions::Users::AppropriateBodyPersona do
  subject(:appropriate_body_persona) do
    described_class.new(email:, name:, appropriate_body_id:, last_active_at:)
  end

  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:email) { "appropriate_body_persona@email.com" }
  let(:name) { "Christopher Lee" }
  let(:appropriate_body_id) { appropriate_body.id }
  let(:last_active_at) { 4.minutes.ago }

  it_behaves_like "a session user" do
    let(:user_props) { {email:, name:, appropriate_body_id:} }
  end

  context "when personas are disabled" do
    before { allow(Rails.application.config).to receive(:enable_personas).and_return(false) }

    it do
      expect { appropriate_body_persona }.to raise_error(described_class::AppropriateBodyPersonaDisabledError)
    end
  end

  context "when no appropriate body is found" do
    let(:appropriate_body_id) { SecureRandom.uuid }

    it do
      expect { appropriate_body_persona }.to raise_error(described_class::UnknownAppropriateBodyId, appropriate_body_id)
    end
  end

  describe "#provider" do
    it { expect(appropriate_body_persona.provider).to be(:persona) }
  end

  describe "#user_type" do
    it { expect(appropriate_body_persona.user_type).to be(:appropriate_body_user) }
  end

  describe "#appropriate_body" do
    it "returns the appropriate_body associated to the persona" do
      expect(appropriate_body_persona.appropriate_body).to eql(appropriate_body)
    end
  end

  describe "#appropriate_body_id" do
    it "returns the appropriate_body_id of the persona" do
      expect(appropriate_body_persona.appropriate_body_id).to eql(appropriate_body_id)
    end
  end

  describe "user type methods" do
    it { expect(appropriate_body_persona).to be_appropriate_body_user }
    it { expect(appropriate_body_persona).not_to be_dfe_sign_in_authorisable }
    it { expect(appropriate_body_persona).not_to be_dfe_user }
    it { expect(appropriate_body_persona).not_to be_school_user }
    it { expect(appropriate_body_persona).not_to be_dfe_user_impersonating_school_user }
  end

  describe "#event_author_params" do
    it "returns a hash with the attributes needed to record an event" do
      expect(appropriate_body_persona.event_author_params).to eql({
        author_email: appropriate_body_persona.email,
        author_name: appropriate_body_persona.name,
        author_type: :appropriate_body_user
      })
    end
  end

  describe "#name" do
    it "returns the name of the appropriate body persona" do
      expect(appropriate_body_persona.name).to eql(name)
    end
  end

  describe "#organisation_name" do
    it "returns the name of the appropriate body associated to the user" do
      expect(appropriate_body_persona.organisation_name).to eq(appropriate_body.name)
    end
  end

  describe "#school_user?" do
    it { expect(appropriate_body_persona).not_to be_school_user }
  end

  describe "#has_authorised_role?" do
    it { expect(appropriate_body_persona).to have_authorised_role }
  end

  describe "#to_h" do
    it "returns attributes for session storage" do
      expect(appropriate_body_persona.to_h).to eql({
        "type" => "Sessions::Users::AppropriateBodyPersona",
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "appropriate_body_id" => appropriate_body_id
      })
    end
  end

  describe "#user" do
    it { expect(appropriate_body_persona.user).to be_nil }
  end
end
