RSpec.describe Admin::ClaimECTActionsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:teacher) { nil }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:component) { described_class.new(teacher:, pending_induction_submission:) }

  describe '#registration_blocked?' do
    context 'when the ECT is exempt from completing their induction' do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, :exempt_from_completing_induction) }

      it 'returns true' do
        expect(component.registration_blocked?).to be true
      end
    end

    context 'when the ECT has an active induction period' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }

      it 'returns true' do
        expect(component.registration_blocked?).to be true
      end
    end

    context 'when the ECT is not exempt and has no active induction period' do
      it 'returns false' do
        expect(component.registration_blocked?).to be false
      end
    end
  end

  describe '#show_claim_form?' do
    context 'when registration is blocked' do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, :exempt_from_completing_induction) }

      it 'returns false' do
        expect(component.show_claim_form?).to be false
      end
    end

    context 'when the ECT has already completed their induction' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:induction_period) { FactoryBot.create(:induction_period, :finished, teacher:) }

      it 'returns false' do
        expect(component.show_claim_form?).to be false
      end
    end

    context 'when the ECT is eligible for claiming' do
      it 'returns true' do
        expect(component.show_claim_form?).to be true
      end
    end
  end

  describe '#blocked_registration_message' do
    context 'when the ECT is exempt from completing their induction' do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, :exempt_from_completing_induction) }

      it 'returns the appropriate message' do
        expect(component.blocked_registration_message).to include("You cannot import #{component.send(:name)}")
        expect(component.blocked_registration_message).to include("is exempt from completing their induction")
      end
    end

    context 'when the ECT has an active induction period' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }

      it 'returns the appropriate message' do
        expect(component.blocked_registration_message).to include("You cannot import #{component.send(:name)}")
        expect(component.blocked_registration_message).to include("already has an active induction period")
      end
    end
  end

  describe 'rendering' do
    context 'when registration is blocked' do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, :exempt_from_completing_induction) }

      it 'renders the blocked message' do
        render_inline(component)

        expect(rendered_component).to have_css('.govuk-inset-text')
        expect(rendered_component).to have_text("You cannot import")
        expect(rendered_component).to have_text("is exempt from completing their induction")
      end

      it 'does not render the claim form' do
        render_inline(component)

        expect(rendered_component).not_to have_css('form')
        expect(rendered_component).not_to have_button('Import ECT')
      end
    end

    context 'when the ECT is eligible for claiming' do
      it 'renders the claim form' do
        render_inline(component)

        expect(rendered_component).to have_css('form')
        expect(rendered_component).to have_button('Import ECT')
      end

      it 'does not render the blocked message' do
        render_inline(component)

        expect(rendered_component).not_to have_css('.govuk-inset-text')
      end
    end
  end
end
