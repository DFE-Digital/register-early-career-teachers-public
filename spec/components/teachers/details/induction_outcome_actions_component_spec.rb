RSpec.describe Teachers::Details::InductionOutcomeActionsComponent, type: :component do
  subject(:component) { described_class.new(mode:, teacher:) }

  let(:mode) { :admin }
  let(:teacher) { FactoryBot.create(:teacher) }

  context "without active induction period" do
    it "does not render" do
      expect(component.render?).to be false
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end

  context "with active induction period" do
    before do
      FactoryBot.create(:induction_period, :active, teacher:)
      render_inline(component)
    end

    it "renders" do
      expect(component.render?).to be true
      render_inline(component)
      expect(rendered_content).not_to be_empty
    end

    context "when in admin mode" do
      let(:mode) { :admin }

      it 'displays fail link' do
        expect(page).to have_link("Fail induction", href: "/admin/teachers/#{teacher.id}/record-failed-outcome/new")
      end

      it 'displays pass link' do
        expect(page).to have_link("Pass induction", href: "/admin/teachers/#{teacher.id}/record-passed-outcome/new")
      end
    end

    context "when in appropriate body mode" do
      let(:mode) { :appropriate_body }

      it 'displays fail link' do
        expect(page).to have_link("Fail induction", href: "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/new")
      end

      it 'displays pass link' do
        expect(page).to have_link("Pass induction", href: "/appropriate-body/teachers/#{teacher.id}/record-passed-outcome/new")
      end
    end
  end
end
