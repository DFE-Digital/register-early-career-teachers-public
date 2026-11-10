RSpec.describe Admin::AppropriateBodies::DescriptionComponent, type: :component do
  subject(:component) { described_class.new(appropriate_body_period:) }

  let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Acme TSH") }
  let(:provisioning_school) do
    FactoryBot.create(
      :school,
      :eligible,
      gias_school: FactoryBot.create(:gias_school, name: "Provisioning School", urn: 100_001)
    )
  end
  let(:name) { teaching_school_hub.name }
  let(:appropriate_body_period) do
    FactoryBot.create(:appropriate_body_period, teaching_school_hub:, provisioning_school:, name:)
  end

  describe "#description" do
    context "with a provisioning school and awarded regions" do
      let(:region_west_east) { FactoryBot.create(:region, code: "R1", districts: %w[West East]) }
      let(:region_north) { FactoryBot.create(:region, code: "R2", districts: %w[North]) }

      before do
        FactoryBot.create(:region_award, appropriate_body_period:, region: region_west_east, school: provisioning_school)
        FactoryBot.create(:region_award, appropriate_body_period:, region: region_north, school: provisioning_school)
      end

      it "includes the provisioning school" do
        expect(component.description).to include("Provisioned by Provisioning School")
      end

      it "counts the awarded regions" do
        expect(component.description).to include("awarded 2 regions")
      end

      it "does not repeat the name, which the template renders alongside it" do
        expect(component.description).not_to start_with(component.display_name)
      end
    end

    context "when a custom trading name is in use" do
      let(:name) { "Acme TSH East" }

      it "leaves the trading name to the template" do
        expect(component.description).not_to include("Acme TSH East")
        expect(component.description).not_to include("Acme TSH")
      end
    end

    context "with a single awarded region" do
      let(:region_north) { FactoryBot.create(:region, code: "R2", districts: %w[North]) }

      before do
        FactoryBot.create(:region_award, appropriate_body_period:, region: region_north, school: provisioning_school)
      end

      it "uses the singular" do
        expect(component.description).to end_with("awarded 1 region")
      end
    end

    context "without awarded regions" do
      it "reports none awarded" do
        expect(component.description).to include("no regions awarded")
      end
    end

    context "when the period is backed by a hub with no provisioning school" do
      let(:appropriate_body_period) do
        # A legacy row: a hub now requires a provisioning school, so write it without validations.
        FactoryBot.build(
          :appropriate_body_period,
          :teaching_school_hub,
          teaching_school_hub:,
          provisioning_school: nil,
          name: nil
        ).tap { |period| period.save!(validate: false) }
      end

      it "says no provisioning school is recorded" do
        expect(component.description).to eq("No provisioning school recorded")
      end
    end

    context "when the period is backed by a national body" do
      let(:national_body) { FactoryBot.create(:national_body, name: "National Body X") }
      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :national, national_body:, name: national_body.name)
      end

      it "has no description yet" do
        expect(component.description).to be_nil
      end
    end

    context "when the period is backed by a local authority" do
      let(:local_authority) { FactoryBot.create(:local_authority, name: "Some Local Authority") }
      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :local_authority, local_authority:, name: local_authority.name)
      end

      it "describes the body as pre-dating regional awards" do
        expect(component.description).to eq("Pre-dates regional awards")
      end
    end

    context "when the period is a legacy teaching school" do
      let(:appropriate_body_period) do
        FactoryBot.create(
          :appropriate_body_period,
          :teaching_school,
          provisioning_school:,
          name: provisioning_school.name
        )
      end

      it "describes the body as pre-dating regional awards" do
        expect(component.description).to eq("Pre-dates regional awards")
      end
    end
  end

  describe "regional awards" do
    let(:region_west_east) { FactoryBot.create(:region, code: "R1", districts: %w[West East]) }
    let(:region_north) { FactoryBot.create(:region, code: "R2", districts: %w[North]) }
    let(:region_south) { FactoryBot.create(:region, code: "R3", districts: %w[South]) }

    before do
      FactoryBot.create(:region_award, appropriate_body_period:, region: region_west_east, school: provisioning_school)
      FactoryBot.create(:region_award, appropriate_body_period:, region: region_north, school: provisioning_school)
      FactoryBot.create(:region_award, appropriate_body_period:, region: region_south, school: provisioning_school)
    end

    context "when the period is backed by a teaching school hub" do
      it "counts the regions awarded to the period" do
        expect(component.description).to include("awarded 3 regions")
      end
    end

    context "when an award has been deactivated" do
      before do
        FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, school: provisioning_school)
      end

      it "counts only the active awards" do
        expect(component.description).to include("awarded 3 regions")
      end
    end
  end

  describe "rendered template" do
    context "when the hub has a single appropriate body" do
      before { render_inline(component) }

      it "renders the description in a GOV.UK paragraph" do
        expect(rendered_content).to have_selector("p.govuk-body", text: component.description)
      end

      it "omits the name, which would repeat the page heading" do
        expect(rendered_content).not_to have_text("#{component.display_name}:")
      end
    end

    context "when the hub has more than one appropriate body" do
      before do
        # A hub with more than one active period now requires a name on each. This row predates that
        # rule, and the component still has to render it, so write it without validations.
        FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                         teaching_school_hub:,
                         provisioning_school:,
                         name: "Acme TSH West").save!(validate: false)

        render_inline(component)
      end

      it "names the body inline, so concurrent bodies can be told apart" do
        expect(rendered_content).to have_selector("p.govuk-body strong", text: "#{component.display_name}:")
      end

      it "describes the body in the same paragraph" do
        expect(rendered_content).to have_selector("p.govuk-body", text: component.description)
      end
    end

    context "when the hub has more than one appropriate body but this one has no name of its own" do
      let(:name) { nil }

      # A hub with more than one active period now requires a name on each. This row predates that
      # rule, and the component still has to render it, so write it without validations.
      let(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, teaching_school_hub:, provisioning_school:, name:)
                  .tap { |period| period.save!(validate: false) }
      end

      before do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:,
                          name: "Acme TSH West")

        render_inline(component)
      end

      it "omits the name, which would repeat the hub name already in the heading" do
        expect(rendered_content).not_to have_selector("strong")
        expect(rendered_content).to have_selector("p.govuk-body", text: component.description)
      end
    end
  end
end
