RSpec.describe SignInHelper, type: :helper do
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  describe "#direct_dfe_sign_in_available?" do
    context "when DfE Sign-in is enabled and personas are disabled" do
      before do
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: true,
          enable_personas: false
        )
      end

      it "returns true" do
        expect(direct_dfe_sign_in_available?).to be(true)
      end
    end

    context "when personas are enabled" do
      before do
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: true,
          enable_personas: true
        )
      end

      it "returns false" do
        expect(direct_dfe_sign_in_available?).to be(false)
      end
    end

    context "when DfE Sign-in is disabled" do
      before do
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: false,
          enable_personas: false
        )
      end

      it "returns false" do
        expect(direct_dfe_sign_in_available?).to be(false)
      end
    end
  end

  describe "#school_sign_in_cta" do
    let(:button_text) { "Continue to DfE Sign-in" }
    let(:rendered_cta) { school_sign_in_cta(button_text) }

    context "when direct school DfE Sign-in is enabled" do
      before do
        allow(Rails.application.config).to receive_messages(
          enable_direct_school_dfe_sign_in: true,
          dfe_sign_in_enabled: true,
          enable_personas: false
        )
      end

      it "renders a POST button to DfE Sign-in" do
        expect(rendered_cta).to have_css("form[action='/auth/dfe_sign_in'][method='post']")
        expect(rendered_cta).to have_button(button_text)
      end
    end

    context "when direct school DfE Sign-in is enabled but DfE Sign-in is not available" do
      before do
        allow(Rails.application.config).to receive_messages(
          enable_direct_school_dfe_sign_in: true,
          dfe_sign_in_enabled: false,
          enable_personas: false
        )
      end

      it "renders a link to the sign in method chooser" do
        expect(rendered_cta).to have_link(button_text, href: sign_in_path)
      end
    end

    context "when direct school DfE Sign-in is disabled" do
      before do
        allow(Rails.application.config).to receive_messages(
          enable_direct_school_dfe_sign_in: false,
          dfe_sign_in_enabled: true,
          enable_personas: false
        )
      end

      it "renders a link to the sign in method chooser" do
        expect(rendered_cta).to have_link(button_text, href: sign_in_path)
      end
    end
  end
end
