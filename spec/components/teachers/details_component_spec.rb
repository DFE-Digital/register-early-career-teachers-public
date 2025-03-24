RSpec.describe Teachers::DetailsComponent, type: :component do
  include ActionView::Helpers::TagHelper
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mode) { :appropriate_body }
  let(:component) { described_class.new(teacher:, mode:) }

  describe "initialization" do
    it "accepts valid modes" do
      valid_modes = %i[admin appropriate_body school]

      valid_modes.each do |valid_mode|
        expect {
          described_class.new(teacher:, mode: valid_mode)
        }.not_to raise_error
      end
    end

    it "rejects invalid modes" do
      expect {
        described_class.new(teacher:, mode: :invalid_mode)
      }.to raise_error(RuntimeError)
    end
  end

  describe "rendering slots" do
    it "renders slots when provided" do
      # Render the component with all slots
      result = render_inline(component) do |c|
        c.with_personal_details
        c.with_itt_details
        c.with_induction_summary
        c.with_current_induction_period
        c.with_past_induction_periods
      end

      # Verify the component renders something
      expect(result.to_html).not_to be_empty
    end

    it "doesn't render slots that aren't provided" do
      # Render the component with no slots
      result = render_inline(component)

      # Verify the component renders an empty string
      expect(result.to_html).to eq("\n\n\n\n\n")
    end
  end

  describe "with different modes" do
    context "when mode is :admin" do
      let(:mode) { :admin }

      it "initializes with admin mode" do
        expect(component.teacher).to eq(teacher)
      end

      it "renders the component with admin mode" do
        # Render the component with the personal_details slot
        result = render_inline(component, &:with_personal_details)

        # Verify the component renders something
        expect(result.to_html).not_to be_empty
      end
    end

    context "when mode is :school" do
      let(:mode) { :school }

      it "initializes with school mode" do
        expect(component.teacher).to eq(teacher)
      end

      it "renders the component with school mode" do
        # Render the component with the personal_details slot
        result = render_inline(component, &:with_personal_details)

        # Verify the component renders something
        expect(result.to_html).not_to be_empty
      end
    end
  end

  describe "slot components" do
    it "passes the teacher to slot components" do
      # Spy on the PersonalDetailsComponent to verify it receives the teacher
      allow(Teachers::Details::PersonalDetailsComponent).to receive(:new).and_call_original

      # Render the component with the personal_details slot
      render_inline(component, &:with_personal_details)

      # Verify the component was created with the correct teacher
      expect(Teachers::Details::PersonalDetailsComponent).to have_received(:new).with(teacher:)
    end
  end

  describe "InductionSummaryComponent" do
    before do
      allow(Teachers::Details::InductionSummaryComponent).to receive(:new).and_call_original
    end

    context "when is_admin is true" do
      it "passes the correct is_admin argument to InductionSummaryComponent" do
        render_inline(component) { |c| c.with_induction_summary(is_admin: true) }

        expect(Teachers::Details::InductionSummaryComponent).to have_received(:new).with(teacher:, is_admin: true)
      end
    end

    context "when is_admin is not specified" do
      it "defaults is_admin to false" do
        render_inline(component, &:with_induction_summary)

        expect(Teachers::Details::InductionSummaryComponent).to have_received(:new).with(teacher:, is_admin: false)
      end
    end
  end
end
