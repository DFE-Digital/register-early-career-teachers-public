RSpec.describe Teachers::ConfirmOutcomeComponent, type: :component do
  subject(:component) do
    described_class.new(service:)
  end

  let(:teacher) { FactoryBot.create(:teacher, :with_name) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
  end
  let(:service) do
    service_class.new(teacher:, appropriate_body:, author:)
  end

  before do
    FactoryBot.create(:induction_period, :ongoing,
                      appropriate_body:,
                      teacher:)
  end

  describe "#render" do
    before { render_inline(component) }

    context "with appropriate body mode" do
      let(:mode) { :appropriate_body }

      context "and failed outcome" do
        let(:service_class) { AppropriateBodies::RecordFail }

        it "targets the appropriate body fail page" do
          expect(rendered_content).to have_selector("form[action='/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/confirm_failed_outcome_checked'][method='post']")
        end

        it "renders a checkbox", :aggregate_failures do
          expect(rendered_content).to have_css(
            'input[type="checkbox"][name="teacher[confirm_failed_outcome][]"]'
          )
          expect(rendered_content).to have_text(
            "Yes, John Keating has been sent written confirmation of their induction outcome, their right to appeal and the appeal process."
          )
        end

        it "shows appeal notice" do
          expect(rendered_content).to have_text("John Keating can appeal this outcome.")
        end

        it "shows link to the appeal process page" do
          expect(rendered_content).to have_css("a.govuk-link[href='https://www.gov.uk/guidance/newly-qualified-teacher-nqt-induction-appeals']")
        end
      end
    end
  end
end
