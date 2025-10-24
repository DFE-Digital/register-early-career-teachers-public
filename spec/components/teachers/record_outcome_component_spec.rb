RSpec.describe Teachers::RecordOutcomeComponent, type: :component do
  subject(:component) do
    described_class.new(mode:, teacher:, outcome:, appropriate_body:, pending_induction_submission:)
  end

  let(:teacher) { FactoryBot.create(:teacher, :with_name) }
  let(:pending_induction_submission) { PendingInductionSubmission.new }

  describe "#render" do
    before { render_inline(component) }

    context "with appropriate body mode" do
      let(:mode) { :appropriate_body }
      let(:appropriate_body) { FactoryBot.build(:appropriate_body) }

      context "and passed outcome" do
        let(:outcome) { :pass }

        it "targets the appropriate body pass action" do
          expect(rendered_content).to have_selector("form[action='/appropriate-body/teachers/#{teacher.id}/record-passed-outcome'][method='post']")
        end

        it "renders a submit button", :aggregate_failures do
          expect(rendered_content).to have_button("Record pass outcome for John Keating")
          expect(rendered_content).to include('govuk-button')
          expect(rendered_content).not_to include('govuk-button--warning')
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to include("John Keating can appeal this outcome.")
        end
      end

      context "and failed outcome" do
        let(:outcome) { :fail }

        it "targets the appropriate body fail action" do
          expect(rendered_content).to have_selector("form[action='/appropriate-body/teachers/#{teacher.id}/record-failed-outcome'][method='post']")
        end

        it "renders a warning button", :aggregate_failures do
          expect(rendered_content).to have_button("Record failing outcome for John Keating")
          expect(rendered_content).to include('govuk-button govuk-button--warning')
        end

        it "shows appeal notice" do
          expect(rendered_content).to have_text("John Keating can appeal this outcome.")
        end
      end
    end

    context "with admin mode" do
      let(:mode) { :admin }
      let(:appropriate_body) { nil }

      context "and passed outcome" do
        let(:outcome) { :pass }

        it "targets the admin pass action" do
          expect(rendered_content).to have_selector("form[action='/admin/teachers/#{teacher.id}/record-passed-outcome'][method='post']")
        end

        it "renders a submit button", :aggregate_failures do
          expect(rendered_content).to have_button("Record pass outcome for John Keating")
          expect(rendered_content).to include('govuk-button')
          expect(rendered_content).not_to include('govuk-button--warning')
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to have_text("John Keating can appeal this outcome.")
        end
      end

      context "and failed outcome" do
        let(:outcome) { :fail }

        it "targets the admin fail action" do
          expect(rendered_content).to have_selector("form[action='/admin/teachers/#{teacher.id}/record-failed-outcome'][method='post']")
        end

        it "renders a warning button", :aggregate_failures do
          expect(rendered_content).to have_button("Record failing outcome for John Keating")
          expect(rendered_content).to include('govuk-button govuk-button--warning')
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to have_text("John Keating can appeal this outcome.")
        end
      end
    end
  end

  describe "#initialize" do
    let(:mode) { :admin }
    let(:outcome) { :pass }
    let(:appropriate_body) { nil }

    context "when appropriate body is omitted in admin mode" do
      subject(:component) do
        described_class.new(mode:, teacher:, outcome:, pending_induction_submission:)
      end

      it do
        expect { component }.not_to raise_error
      end
    end

    context "when appropriate body is omitted in appropriate body mode" do
      subject(:component) do
        described_class.new(mode:, teacher:, outcome:, pending_induction_submission:)
      end

      let(:mode) { :appropriate_body }

      it do
        expect { component }.to raise_error(Teachers::RecordOutcomeComponent::MissingAppropriateBodyError)
      end
    end

    context "when outcome is not recognised" do
      let(:outcome) { :foo }

      it do
        expect { component }.to raise_error(Teachers::RecordOutcomeComponent::InvalidOutcomeError)
      end
    end

    context "when mode is not recognised" do
      let(:mode) { :invalid_mode }

      it do
        expect { component }.to raise_error(UserModes::InvalidModeError)
      end
    end
  end
end
