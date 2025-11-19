RSpec.describe DebugSessionComponent, type: :component do
  subject(:component) { described_class.new }

  let(:current_user) do
    FactoryBot.create(:dfe_user,
                      name: "Patch Adams",
                      role: "super_admin")
  end

  let(:current_session) do
    {
      "Type"	=> current_user.class.name,
      "Email"	=> current_user.email,
      "Last active at" =>	"1999-01-01 00:00:01 +0100"
    }
  end

  before do
    Current.user = current_user
    Current.session = current_session
  end

  context "when disabled" do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(false)
      render_inline(component)
    end

    it { expect(rendered_content).to be_blank }
  end

  context "when enabled" do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
      render_inline(component)
    end

    it { expect(rendered_content).not_to be_blank }

    it "summarises session and user details" do
      aggregate_failures do
        expect(rendered_content).to have_text("Type")
        expect(rendered_content).to have_text("Sessions::Users::DfEUser")
        expect(rendered_content).to have_text("Email")
        expect(rendered_content).to have_text("@example.com")
        expect(rendered_content).to have_text("Last active at")
        expect(rendered_content).to have_text("1999-01-01 00:00:01 +0100")
        expect(rendered_content).to have_text("Role")
        expect(rendered_content).to have_text("Super admin")
        expect(rendered_content).to have_text("Administrator")
        expect(rendered_content).to have_text("Patch Adams")
      end
    end

    context "and the user is not a DfE user" do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:current_user) do
        FactoryBot.create(:appropriate_body_user,
                          dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
      end

      it "does not display admin information" do
        expect(rendered_content).not_to have_text("Administrator")
        expect(rendered_content).not_to have_text("Role")
      end
    end
  end
end
