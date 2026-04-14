RSpec.describe PagesHelper, type: :helper do
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  describe "#school_sign_in_cta" do
    let(:button_text) { "Continue to DfE Sign-in" }
    let(:rendered_cta) { school_sign_in_cta(button_text) }

    context "when in production and DfE Sign-in is enabled" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: true,
          enable_personas: false
        )
      end

      it "renders a POST button to DfE Sign-in" do
        expect(rendered_cta).to have_css("form[action='/auth/dfe_sign_in'][method='post']")
        expect(rendered_cta).to have_button(button_text)
      end
    end

    context "when in production but personas are enabled" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: true,
          enable_personas: true
        )
      end

      it "renders a link to the sign in method chooser" do
        expect(rendered_cta).to have_link(button_text, href: sign_in_path)
      end
    end

    context "when in production but DfE Sign-in is not available" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(Rails.application.config).to receive_messages(
          dfe_sign_in_enabled: false,
          enable_personas: false
        )
      end

      it "renders a link to the sign in method chooser" do
        expect(rendered_cta).to have_link(button_text, href: sign_in_path)
      end
    end

    context "when not in production" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("sandbox"))
        allow(Rails.application.config).to receive_messages(
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
