RSpec.describe Teachers::DetailsComponent, type: :component do
  include ActionView::Helpers::TagHelper
  let(:teacher) { create(:teacher) }
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
    context "when mode is :admin" do
      let(:mode) { :admin }

      before do
        allow(Teachers::Details::AdminInductionSummaryComponent).to receive(:new).and_call_original
      end

      it "uses AdminInductionSummaryComponent" do
        render_inline(component, &:with_induction_summary)

        expect(Teachers::Details::AdminInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end

    context "when mode is :appropriate_body" do
      let(:mode) { :appropriate_body }

      before do
        allow(Teachers::Details::AppropriateBodyInductionSummaryComponent).to receive(:new).and_call_original
      end

      it "uses AppropriateBodyInductionSummaryComponent" do
        render_inline(component, &:with_induction_summary)

        expect(Teachers::Details::AppropriateBodyInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end

    context "when mode is :school" do
      let(:mode) { :school }

      before do
        allow(Teachers::Details::AppropriateBodyInductionSummaryComponent).to receive(:new).and_call_original
      end

      it "uses AppropriateBodyInductionSummaryComponent for school mode" do
        render_inline(component, &:with_induction_summary)

        expect(Teachers::Details::AppropriateBodyInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end
  end
end
