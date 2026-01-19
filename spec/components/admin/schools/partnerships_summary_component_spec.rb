RSpec.describe Admin::Schools::PartnershipsSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(school:)) }

  include Rails.application.routes.url_helpers

  let(:school) { FactoryBot.create(:school) }
  let(:current_year) { Time.zone.today.year }
  let(:previous_year) { current_year - 1 }

  context "with multiple partnerships" do
    let!(:partnership_2024) do
      FactoryBot.create(:school_partnership, :for_year,
                        school:,
                        year: current_year,
                        lead_provider: FactoryBot.create(:lead_provider, name: "Alpha Provider"),
                        delivery_partner: FactoryBot.create(:delivery_partner, name: "Delta Partner"))
    end

    let!(:partnership_2023) do
      FactoryBot.create(:school_partnership, :for_year,
                        school:,
                        year: previous_year,
                        lead_provider: FactoryBot.create(:lead_provider, name: "Beta Provider"),
                        delivery_partner: FactoryBot.create(:delivery_partner, name: "Gamma Partner"))
    end

    describe "contract period headings" do
      it "shows headings for each contract period" do
        expect(rendered).to have_css("h3", text: "#{current_year} partnerships")
        expect(rendered).to have_css("h3", text: "#{previous_year} partnerships")
      end

      it "orders contract period headings with most recent first" do
        body = rendered.to_html
        newer = body.index("#{current_year} partnerships")
        older = body.index("#{previous_year} partnerships")
        expect(newer).not_to be_nil
        expect(older).not_to be_nil
        expect(newer).to be < older
      end
    end

    describe "card titles" do
      it "renders the lead provider and delivery partner names and API id" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Alpha Provider and Delta Partner")
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Beta Provider and Gamma Partner")
      end
    end

    describe "lead provider row" do
      it "renders" do
        expect(rendered).to have_css("dt", text: "Lead provider")
        expect(rendered).to have_css("dd", text: "Alpha Provider")
      end
    end

    describe "delivery partner row" do
      it "renders" do
        expect(rendered).to have_css("dt", text: "Delivery partner")
        expect(rendered).to have_css("dd", text: "Delta Partner")
      end
    end

    describe "API ID row" do
      it "renders" do
        expect(rendered).to have_css("dt", text: "Partnership API ID")
        expect(rendered).to have_css("dd", text: partnership_2024.api_id)
        expect(rendered).to have_css("dd", text: partnership_2023.api_id)
      end
    end
  end

  context "with teacher rows" do
    let!(:partnership_with_teachers) do
      FactoryBot.create(:school_partnership, :for_year,
                        school:,
                        year: current_year,
                        lead_provider: FactoryBot.create(:lead_provider, name: "Alpha Provider"),
                        delivery_partner: FactoryBot.create(:delivery_partner, name: "Delta Partner"))
    end

    let!(:partnership_without_teachers) do
      FactoryBot.create(:school_partnership, :for_year,
                        school:,
                        year: previous_year,
                        lead_provider: FactoryBot.create(:lead_provider, name: "Beta Provider"),
                        delivery_partner: FactoryBot.create(:delivery_partner, name: "Gamma Partner"))
    end

    let!(:ect_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }
    let!(:mentor_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:) }
    let!(:finished_ect_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 2.years.ago, finished_on: 1.year.ago) }
    let!(:future_mentor_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 1.month.from_now, finished_on: nil) }

    let!(:ect_training_period) do
      FactoryBot.create(:training_period,
                        :for_ect,
                        :ongoing,
                        ect_at_school_period: ect_period,
                        school_partnership: partnership_with_teachers)
    end

    let!(:mentor_training_period) do
      FactoryBot.create(:training_period,
                        :for_mentor,
                        :ongoing,
                        mentor_at_school_period: mentor_period,
                        school_partnership: partnership_with_teachers)
    end

    let!(:finished_ect_training_period) do
      FactoryBot.create(:training_period,
                        :for_ect,
                        ect_at_school_period: finished_ect_period,
                        school_partnership: partnership_with_teachers)
    end

    let!(:future_mentor_training_period) do
      FactoryBot.create(:training_period,
                        :for_mentor,
                        mentor_at_school_period: future_mentor_period,
                        school_partnership: partnership_with_teachers)
    end

    describe "teacher rows" do
      it "lists linked ECTs with links" do
        expect(rendered).to have_link(Teachers::Name.new(ect_period.teacher).full_name, href: admin_teacher_induction_path(ect_period.teacher))
      end

      it "lists linked mentors with links" do
        expect(rendered).to have_link(Teachers::Name.new(mentor_period.teacher).full_name, href: admin_teacher_induction_path(mentor_period.teacher))
      end

      it "lists teachers alphabetically" do
        z_teacher = FactoryBot.create(:teacher, corrected_name: "Z Teacher")
        a_teacher = FactoryBot.create(:teacher, corrected_name: "A Teacher")

        z_period = FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: z_teacher)
        a_period = FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: a_teacher)

        FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period: z_period, school_partnership: partnership_with_teachers)
        FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period: a_period, school_partnership: partnership_with_teachers)

        body = rendered.to_html
        a_index = body.index("A Teacher")
        z_index = body.index("Z Teacher")

        expect(a_index).not_to be_nil
        expect(z_index).not_to be_nil
        expect(a_index).to be < z_index
      end

      it "only shows current ECTs and mentors" do
        finished_name = Teachers::Name.new(finished_ect_period.teacher).full_name
        future_name = Teachers::Name.new(future_mentor_period.teacher).full_name

        expect(rendered).not_to have_link(finished_name, href: admin_teacher_induction_path(finished_ect_period.teacher))
        expect(rendered).not_to have_link(future_name, href: admin_teacher_induction_path(future_mentor_period.teacher))
      end

      it "shows fallbacks when no teachers are linked" do
        partnership_card = rendered.css(".govuk-summary-card").find do |card|
          card.text.include?("Beta Provider and Gamma Partner")
        end
        expect(partnership_card).to have_css(".govuk-summary-list__row", text: /ECTs.*None assigned/)
        expect(partnership_card).to have_css(".govuk-summary-list__row", text: /Mentors.*None assigned/)
      end
    end
  end

  context "when there are no partnerships" do
    it "shows the empty state" do
      expect(rendered).to have_text("No partnerships recorded for this school.")
    end
  end
end
