RSpec.describe Teachers::RecordOutcomeComponent, type: :component do
  subject(:component) do
    described_class.new(mode:, service:)
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

      context "and passed outcome" do
        let(:service_class) { AppropriateBodies::RecordPass }

        it "targets the appropriate body pass action" do
          expect(rendered_content).to have_selector("form[action='/appropriate-body/teachers/#{teacher.id}/record-passed-outcome'][method='post']")
        end

        it "renders a submit button", :aggregate_failures do
          expect(rendered_content).to have_button("Record pass outcome for John Keating")
          expect(rendered_content).to include("govuk-button")
          expect(rendered_content).not_to include("govuk-button--warning")
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to include("John Keating can appeal this outcome.")
        end
      end

      context "and failed outcome" do
        let(:service_class) { AppropriateBodies::RecordFail }

        it "targets the appropriate body fail action" do
          expect(rendered_content).to have_selector("form[action='/appropriate-body/teachers/#{teacher.id}/record-failed-outcome'][method='post']")
        end

        it "renders a warning button", :aggregate_failures do
          expect(rendered_content).to have_button("Record failing outcome for John Keating")
          expect(rendered_content).to include("govuk-button govuk-button--warning")
        end

        it "shows appeal notice" do
          expect(rendered_content).to have_text("John Keating can appeal this outcome.")
        end
      end
    end

    context "with admin mode" do
      let(:mode) { :admin }
      let(:author) { FactoryBot.create(:dfe_user) }

      context "and passed outcome" do
        let(:service_class) { Admin::RecordPass }

        it "targets the admin pass action" do
          expect(rendered_content).to have_selector("form[action='/admin/teachers/#{teacher.id}/record-passed-outcome'][method='post']")
        end

        it "renders a submit button", :aggregate_failures do
          expect(rendered_content).to have_button("Record pass outcome for John Keating")
          expect(rendered_content).to include("govuk-button")
          expect(rendered_content).not_to include("govuk-button--warning")
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to have_text("John Keating can appeal this outcome.")
        end
      end

      context "and failed outcome" do
        let(:service_class) { Admin::RecordFail }

        it "targets the admin fail action" do
          expect(rendered_content).to have_selector("form[action='/admin/teachers/#{teacher.id}/record-failed-outcome'][method='post']")
        end

        it "renders a warning button", :aggregate_failures do
          expect(rendered_content).to have_button("Record failing outcome for John Keating")
          expect(rendered_content).to include("govuk-button govuk-button--warning")
        end

        it "hides appeal notice" do
          expect(rendered_content).not_to have_text("John Keating can appeal this outcome.")
        end
      end
    end
  end

  describe "#initialize" do
    context "with an invalid mode" do
      let(:mode) { :invalid_mode }
      let(:service_class) { AppropriateBodies::RecordPass }

      it do
        expect { described_class.new(mode:, service:) }
        .to raise_error(UserModes::InvalidModeError)
      end
    end

    context "with an invalid service" do
      let(:mode) { :appropriate_body }
      let(:service_class) { AppropriateBodies::RecordRelease }

      it do
        expect { described_class.new(mode:, service:) }
        .to raise_error(Teachers::RecordOutcomeComponent::InvalidServiceError)
      end
    end

    context "with an invalid outcome" do
      let(:mode) { :admin }
      let(:service_class) { Admin::RecordPass }

      before do
        allow(service).to receive(:outcome).and_return(:failed)
      end

      it do
        expect { described_class.new(mode:, service:) }
        .to raise_error(Teachers::RecordOutcomeComponent::InvalidOutcomeError)
      end
    end
  end
end
