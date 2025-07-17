RSpec.describe Teachers::DetailsComponent, type: :component do
  include ActionView::Helpers::TagHelper
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mode) { :appropriate_body }
  let(:component) { described_class.new(teacher:, mode:) }

  describe "modes" do
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

  it "has slots" do
    expect(component).to respond_to(:personal_details)
    expect(component).to respond_to(:induction_summary)
    expect(component).to respond_to(:current_induction_period)
    expect(component).to respond_to(:itt_details)
    expect(component).to respond_to(:past_induction_periods)
    expect(component).to respond_to(:induction_outcome_actions)
  end

  describe "#personal_details" do
    before do
      allow(Teachers::Details::PersonalDetailsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_personal_details)
    end

    it "passes the teacher to slot component" do
      expect(Teachers::Details::PersonalDetailsComponent).to have_received(:new).with(teacher:)
    end
  end

  describe "#induction_summary" do
    context "when mode is :admin" do
      let(:mode) { :admin }

      before do
        allow(Teachers::Details::AdminInductionSummaryComponent).to receive(:new).and_call_original
        render_inline(component, &:with_induction_summary)
      end

      it "uses AdminInductionSummaryComponent" do
        expect(Teachers::Details::AdminInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end

    context "when mode is :appropriate_body" do
      let(:mode) { :appropriate_body }

      before do
        allow(Teachers::Details::AppropriateBodyInductionSummaryComponent).to receive(:new).and_call_original
        render_inline(component, &:with_induction_summary)
      end

      it "uses AppropriateBodyInductionSummaryComponent" do
        expect(Teachers::Details::AppropriateBodyInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end

    context "when mode is :school" do
      let(:mode) { :school }

      before do
        allow(Teachers::Details::AppropriateBodyInductionSummaryComponent).to receive(:new).and_call_original
        render_inline(component, &:with_induction_summary)
      end

      it "uses AppropriateBodyInductionSummaryComponent for school mode" do
        expect(Teachers::Details::AppropriateBodyInductionSummaryComponent).to have_received(:new).with(teacher:)
      end
    end
  end

  describe "#current_induction_period" do
    before do
      allow(Teachers::Details::CurrentInductionPeriodComponent).to receive(:new).and_call_original
    end

    it 'passes mode and teacher to slot component and defaults enable flags to false' do
      render_inline(component.with_current_induction_period)

      expect(Teachers::Details::CurrentInductionPeriodComponent).to have_received(:new).with(mode:,
                                                                                             teacher:,
                                                                                             enable_delete: false,
                                                                                             enable_edit: false,
                                                                                             enable_release: false)
    end

    it 'sets enable edit, delete and release flags' do
      render_inline(component.with_current_induction_period(enable_release: true, enable_edit: true, enable_delete: true))

      expect(Teachers::Details::CurrentInductionPeriodComponent).to have_received(:new).with(mode:,
                                                                                             teacher:,
                                                                                             enable_delete: true,
                                                                                             enable_edit: true,
                                                                                             enable_release: true)
    end
  end

  describe "#itt_details" do
    before do
      allow(Teachers::Details::ITTDetailsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_itt_details)
    end

    it "passes the teacher to slot component" do
      expect(Teachers::Details::ITTDetailsComponent).to have_received(:new).with(teacher:)
    end
  end

  describe "#induction_outcome_actions" do
    before do
      allow(Teachers::Details::InductionOutcomeActionsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_induction_outcome_actions)
    end

    it "passes the mode and teacher to slot component" do
      expect(Teachers::Details::InductionOutcomeActionsComponent).to have_received(:new).with(mode:, teacher:)
    end
  end

  describe "#past_induction_periods" do
    before do
      allow(Teachers::Details::PastInductionPeriodsComponent).to receive(:new).and_call_original
    end

    it "passes the teacher slot component and defaults enable flag to false" do
      render_inline(component.with_past_induction_periods)
      expect(Teachers::Details::PastInductionPeriodsComponent).to have_received(:new).with(teacher:, enable_edit: false)
    end

    it "sets enable edit flag" do
      render_inline(component.with_past_induction_periods(enable_edit: true))
      expect(Teachers::Details::PastInductionPeriodsComponent).to have_received(:new).with(teacher:, enable_edit: true)
    end
  end
end
