RSpec.describe Admin::TeachingSchoolHubs::SummaryCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(teaching_school_hub:) }

  let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network") }
  let(:provisioning_school) do
    FactoryBot.create(
      :school,
      :eligible,
      gias_school: FactoryBot.create(:gias_school, name: "Eden Boys' Bolton", urn: 140_959)
    )
  end

  describe "rendered template" do
    context "when the hub has one appropriate body period" do
      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: nil)

        render_inline(component)
      end

      it "links the hub name to the hub page" do
        expect(rendered_content).to have_link("Star Teaching School Hub Network",
                                              href: admin_teaching_school_hub_path(teaching_school_hub))
      end

      it "describes the body, naming its provisioning school" do
        expect(rendered_content).to have_selector("p.govuk-body",
                                                  text: "Provisioned by #{provisioning_school.name}")
      end
    end

    context "when the hub has more than one appropriate body period" do
      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Beta period")
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Alpha period")

        render_inline(component)
      end

      it "renders the periods in name order" do
        expect(rendered_content).to have_text(/Alpha period.*Beta period/m)
        expect(rendered_content).not_to have_text(/Beta period.*Alpha period/m)
      end

      it "names each period, so concurrent bodies can be told apart" do
        expect(rendered_content).to have_selector("strong", text: "Alpha period:")
      end

      it "names the hub once, not once per period" do
        expect(page.text.scan(teaching_school_hub.name).size).to eq(1)
      end
    end

    context "when one of those periods has no name of its own" do
      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Named period")
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: nil)

        render_inline(component)
      end

      it "emboldens only the period that has a name of its own" do
        expect(rendered_content).to have_selector("strong", text: "Named period:")
        expect(rendered_content).not_to have_selector("strong", text: teaching_school_hub.name)
      end

      it "does not pass the hub name off as that period's name" do
        expect(page.text.scan(teaching_school_hub.name).size).to eq(1)
      end
    end

    context "when the hub has no appropriate body periods" do
      before { render_inline(component) }

      it "says so, rather than showing an empty card" do
        expect(rendered_content).to have_text("No appropriate body periods yet")
      end
    end
  end
end
