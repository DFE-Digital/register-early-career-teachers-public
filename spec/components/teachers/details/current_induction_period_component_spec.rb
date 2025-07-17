RSpec.describe Teachers::Details::CurrentInductionPeriodComponent, type: :component do
  subject(:component) { described_class.new(mode:, teacher:) }

  let(:mode) { :appropriate_body }
  let(:teacher) { FactoryBot.create(:teacher) }

  context "when teacher has no current induction period" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has a current induction period" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Test AB") }
    let!(:current_period) do
      FactoryBot.create(:induction_period, :active,
                        teacher:,
                        appropriate_body:,
                        started_on: '2025-06-30',
                        induction_programme: 'fip')
    end

    before { render_inline(component) }

    it "renders" do
      expect(component.render?).to be true
    end

    it "displays the heading" do
      expect(page).to have_css("h2", text: "Current induction period")
    end

    it "displays the appropriate body name" do
      expect(page).to have_css("h3", text: "Test AB")
    end

    it "formats the start date" do
      expect(page).to have_text('30 June 2025')
    end

    describe '#enable_release' do
      subject(:component) { described_class.new(mode:, teacher:, enable_release:) }

      context "when true" do
        let(:enable_release) { true }

        context "and in admin mode" do
          let(:mode) { :admin }

          it { expect(page).not_to have_link("Release") }
        end

        context "and in appropriate body mode" do
          it "renders appropriate body release link" do
            expect(page).to have_link("Release", href: "/appropriate-body/teachers/#{teacher.id}/release/new")
          end
        end
      end

      context "when false" do
        let(:enable_release) { false }

        it {
          expect(page).not_to have_link("Release")
        }
      end
    end

    describe '#enable_edit' do
      subject(:component) { described_class.new(mode:, teacher:, enable_edit:) }

      context "when true" do
        let(:enable_edit) { true }

        context "and in admin mode" do
          let(:mode) { :admin }

          it "renders admin edit link" do
            expect(page).to have_link("Edit", href: "/admin/teachers/#{teacher.id}/induction-periods/#{current_period.id}/edit")
          end
        end

        context "and in appropriate body mode" do
          let(:mode) { :appropriate_body }

          it "renders appropriate body edit link" do
            expect(page).to have_link("Edit", href: "/appropriate-body/teachers/#{teacher.id}/induction-periods/#{current_period.id}/edit")
          end
        end

        context "when the induction period has an outcome" do
          let!(:current_period) do
            FactoryBot.create(:induction_period, :active,
                              teacher:,
                              appropriate_body:,
                              started_on: 6.months.ago,
                              outcome: "pass",
                              induction_programme: "cip")
          end

          it { expect(page).to have_link("Edit") }
        end
      end

      context "when false" do
        let(:enable_edit) { false }

        it { expect(page).not_to have_link("Edit") }
      end
    end

    describe '#enable_delete' do
      subject(:component) { described_class.new(mode:, teacher:, enable_delete:) }

      before { render_inline(component) }

      context "when true" do
        let(:enable_delete) { true }

        context "and in admin mode" do
          let(:mode) { :admin }

          it "renders admin delete link" do
            expect(page).to have_link("Delete", href: "/admin/teachers/#{teacher.id}/induction-periods/#{current_period.id}/confirm-delete")
          end
        end

        context "and in appropriate body mode" do
          let(:mode) { :appropriate_body }

          it { expect(page).not_to have_link("Delete") }
        end
      end

      context "when false" do
        let(:enable_delete) { false }

        it { expect(page).not_to have_link("Delete") }
      end
    end
  end
end
