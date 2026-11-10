RSpec.describe Admin::TeachingSchoolHubs::SummaryCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(teaching_school_hub:) }

  let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Acme TSH") }
  let(:provisioning_school) do
    FactoryBot.create(
      :school,
      :eligible,
      gias_school: FactoryBot.create(:gias_school, name: "Provisioning School", urn: 100_001)
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
        expect(rendered_content).to have_link("Acme TSH",
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
                          name: "Acme TSH West")
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Acme TSH East")

        render_inline(component)
      end

      it "renders the periods in name order" do
        expect(rendered_content).to have_text(/Acme TSH East.*Acme TSH West/m)
        expect(rendered_content).not_to have_text(/Acme TSH West.*Acme TSH East/m)
      end

      it "names each period, so concurrent bodies can be told apart" do
        expect(rendered_content).to have_selector("strong", text: "Acme TSH East:")
        expect(rendered_content).to have_selector("strong", text: "Acme TSH West:")
      end

      it "names the hub once, not once per period" do
        expect(page).to have_link(teaching_school_hub.name, count: 1)
      end

      it "gives each period a label of its own" do
        labels = page.all("strong").map { it.text.delete_suffix(":") }

        expect(labels.size).to eq(2)
        expect(labels.uniq).to eq(labels)
      end
    end

    context "when one of those periods has no name of its own" do
      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Acme TSH East")
        # A hub with more than one active period now requires a name on each. This row predates that
        # rule, and the card still has to render it, so write it without validations.
        FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                         teaching_school_hub:,
                         provisioning_school:,
                         name: nil).save!(validate: false)

        render_inline(component)
      end

      it "emboldens only the period that has a name of its own" do
        expect(rendered_content).to have_selector("strong", text: "Acme TSH East:")
        expect(rendered_content).not_to have_selector("strong", text: "#{teaching_school_hub.name}:")
      end

      it "does not pass the hub name off as that period's name" do
        expect(rendered_content).not_to have_selector("strong", text: "#{teaching_school_hub.name}:")
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
