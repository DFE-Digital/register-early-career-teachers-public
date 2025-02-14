# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppropriateBodies::ClaimECTActionsComponent, type: :component do
  let(:teacher) { nil }
  let(:current_appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:pending_induction_submission) do
    FactoryBot.create(
      :pending_induction_submission,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
  end

  subject(:component) do
    described_class.new(
      teacher: teacher,
      pending_induction_submission: pending_induction_submission,
      current_appropriate_body: current_appropriate_body
    )
  end

  context "when teacher is registered with another appropriate body" do
    let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:teacher) { FactoryBot.create(:teacher) }
    let!(:induction_period) do
      FactoryBot.create(
        :induction_period,
        :active,
        teacher: teacher,
        appropriate_body: other_appropriate_body
      )
    end

    it "renders inset text explaining teacher cannot be registered" do
      render_inline(component)

      expect(page).to have_text("You cannot register John Doe")
      expect(page).to have_text("Our records show that John Doe is completing their induction with another appropriate body")
      expect(page).not_to have_button("Claim induction")
    end
  end

  context "when teacher can be claimed" do
    context "when induction is not completed" do
      let(:teacher) { FactoryBot.create(:teacher) }

      it "renders the claim induction form" do
        render_inline(component)

        expect(page).to have_button("Claim induction")
        expect(page).not_to have_text("You cannot register John Doe")
      end
    end

    context "when induction is completed" do
      let(:teacher) { FactoryBot.create(:teacher) }

      before do
        allow_any_instance_of(::Teachers::InductionStatus)
          .to receive(:completed?)
          .and_return(true)
      end

      it "does not render the claim induction form" do
        render_inline(component)

        expect(page).not_to have_button("Claim induction")
        expect(page).not_to have_text("You cannot register John Doe")
      end
    end
  end
end
