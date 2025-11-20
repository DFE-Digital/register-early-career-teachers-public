RSpec.describe Admin::AppropriateBodies::DetailsComponent, type: :component do
  subject(:component) { described_class.new(appropriate_body:) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  before { render_inline(component) }

  describe "ECTs" do
    context "with current ECTs" do
      before do
        FactoryBot.create(:induction_period, :ongoing, appropriate_body:)
        render_inline(component)
      end

      it do
        expect(rendered_content).to have_link("View current ECTs",
                                              href: "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/current-ects")
      end
    end

    context "without current ECTs" do
      it do
        expect(rendered_content).not_to have_link("View current ECTs")
      end
    end
  end

  describe "bulk uploads" do
    context "with activity" do
      before do
        FactoryBot.create(:pending_induction_submission_batch, :claim, :completed, appropriate_body:)
        render_inline(component)
      end

      it do
        expect(rendered_content).to have_link("View bulk uploads",
                                              href: "/admin/organisations/appropriate-bodies/#{appropriate_body.id}/batches")
      end
    end

    context "without activity" do
      it do
        expect(rendered_content).not_to have_link("View bulk uploads")
      end
    end
  end
end
