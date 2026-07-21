describe EnvironmentHelper do
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper
  include GovukComponentsHelper
  include ApplicationHelper

  before do
    stub_const("ENVIRONMENT_COLOUR", nil)
    stub_const("ENVIRONMENT_PHASE_BANNER_TAG", nil)
    stub_const("ENVIRONMENT_PHASE_BANNER_CONTENT", nil)
  end

  describe "#environment_specific_header_colour_class" do
    it("is nil when no colour is set (defaults to blue)") do
      expect(environment_specific_header_colour_class).to be_nil
    end

    context "when ENVIRONMENT_COLOUR is set to 'magenta'" do
      it "returns a magenta modifier class" do
        stub_const("ENVIRONMENT_COLOUR", "magenta")
        expect(environment_specific_header_colour_class).to eql("app-header--magenta")
      end
    end
  end

  describe "#environment_specific_phase_banner_arguments" do
    subject { environment_specific_phase_banner_arguments }

    it "is 'Beta' by default" do
      expect(subject.dig(:tag, :text)).to eql("Beta")
    end

    it "has a govuk tag with no colour modifier" do
      expect(subject.dig(:tag, :colour)).to be_nil
    end

    it "adds the govuk-width-container class to the phase banner arg" do
      expect(subject.dig(:html_attributes, :class)).to include("govuk-width-container")
    end

    context "when ENVIRONMENT_PHASE_BANNER_TAG is not set" do
      it "includes the default text" do
        expect(subject.fetch(:text)).to start_with("This is a new service")
      end

      it "includes the support feedback form" do
        expect(subject.fetch(:text)).to include(EnvironmentHelper::FEEDBACK_SURVEY_FORM_URL)
      end
    end

    context "when ENVIRONMENT_COLOUR, ENVIRONMENT_PHASE_BANNER_CONTENT and ENVIRONMENT_PHASE_BANNER_TAG are set" do
      before do
        stub_const("ENVIRONMENT_COLOUR", "yellow")
        stub_const("ENVIRONMENT_PHASE_BANNER_TAG", "Wow")
        stub_const("ENVIRONMENT_PHASE_BANNER_CONTENT", "What a nice service")
      end

      it "overwrites the default with the provided value" do
        expect(subject.dig(:tag, :text)).to eql("Wow")
      end

      it "has a govuk tag with a yellow modifier class" do
        expect(subject.dig(:tag, :colour)).to eql("yellow")
      end

      it "contains the text 'Give feedback about this service'" do
        expect(subject.fetch(:text)).to include("What a nice service")
      end
    end

    context "when inverse is true" do
      subject { environment_specific_phase_banner_arguments(inverse: true) }

      it "adds the inverse class to the phase banner arg" do
        expect(subject.dig(:html_attributes, :class)).to match_array(%w[govuk-width-container x-govuk-phase-banner--inverse])
      end

      it "adds the inverse class to the phase banner tag arg" do
        expect(subject.dig(:tag, :html_attributes, :class)).to include("x-govuk-tag--inverse")
      end
    end
  end
end
