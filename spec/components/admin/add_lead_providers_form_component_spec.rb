RSpec.describe Admin::AddLeadProvidersFormComponent, type: :component do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:year) { 2025 }
  let(:page) { "2" }
  let(:q) { "search" }

  let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider One") }
  let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider Two") }
  let(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider Three") }

  let(:contract_period) { FactoryBot.create(:contract_period, year:, started_on: 1.month.ago, finished_on: 1.month.from_now) }
  let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }
  let(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_3, contract_period:) }

  let(:current_partnerships) do
    [
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_1)
    ]
  end

  let(:available_lead_providers) { [active_lead_provider_2, active_lead_provider_3] }

  let(:component) do
    described_class.new(
      delivery_partner:,
      current_partnerships:,
      available_lead_providers:,
      year:,
      page:,
      q:
    )
  end

  describe "component logic and methods" do
    describe "#current_partnership_names" do
      it "returns array of lead provider names" do
        names = component.send(:current_partnership_names)
        expect(names).to eq(["Lead Provider One"])
      end
    end

    describe "#legend_text" do
      it "returns correct legend text" do
        expect(component.send(:legend_text)).to eq("Add new lead providers")
      end
    end

    describe "#hint_text" do
      it "returns correct hint text" do
        hint = component.send(:hint_text)
        expect(hint).to include("Test Delivery Partner")
        expect(hint).to include("2025")
        expect(hint).to include("Select additional lead providers")
      end
    end

    describe "#form_url" do
      it "generates correct form URL" do
        render_inline(component) # Render first to make helpers available
        url = component.send(:form_url)
        expect(url).to include("/admin/organisations/delivery-partners/#{delivery_partner.id}")
      end
    end

    describe "#back_link_path" do
      it "generates correct path with parameters" do
        render_inline(component) # Render first to make helpers available
        path = component.send(:back_link_path)
        expect(path).to include("/admin/organisations/delivery-partners/#{delivery_partner.id}")
        expect(path).to include("page=2")
        expect(path).to include("q=search")
      end

      context "when page and q are nil" do
        let(:component) do
          described_class.new(
            delivery_partner:,
            current_partnerships:,
            available_lead_providers:,
            year:
          )
        end

        it "generates path without page/q parameters" do
          render_inline(component) # Render first to make helpers available
          path = component.send(:back_link_path)
          expect(path).to include("/admin/organisations/delivery-partners/#{delivery_partner.id}")
          expect(path).not_to include("page=")
          expect(path).not_to include("q=")
        end
      end
    end
  end

  describe "component rendering behavior" do
    it "renders successfully" do
      expect { render_inline(component) }.not_to raise_error
    end

    it "renders successfully with no current partnerships" do
      component_without_partnerships = described_class.new(
        delivery_partner:,
        current_partnerships: [],
        available_lead_providers:,
        year:,
        page:,
        q:
      )
      expect { render_inline(component_without_partnerships) }.not_to raise_error
    end

    it "shows existing partnerships in inset text" do
      result = render_inline(component)

      expect(result.to_html).to include("Currently working with:")
      expect(result.to_html).to include("Lead Provider One")
    end

    it "shows available providers as checkboxes" do
      result = render_inline(component)

      # Check for checkbox inputs with the correct values
      checkbox_2 = result.css('input[type="checkbox"][value="' + active_lead_provider_2.id.to_s + '"]').first
      checkbox_3 = result.css('input[type="checkbox"][value="' + active_lead_provider_3.id.to_s + '"]').first

      expect(checkbox_2).to be_present
      expect(checkbox_3).to be_present

      # Check for labels
      expect(result.to_html).to include("Lead Provider Two")
      expect(result.to_html).to include("Lead Provider Three")
    end

    it "does not show existing partnerships as checkboxes" do
      result = render_inline(component)

      # Lead Provider One should not be a checkbox since it's already a partnership
      checkbox_1 = result.css('input[type="checkbox"][value="' + active_lead_provider_1.id.to_s + '"]')
      expect(checkbox_1).to be_empty
    end

    context "when there are no current partnerships" do
      let(:current_partnerships) { [] }

      it "does not show inset text or hidden fields" do
        result = render_inline(component)

        expect(result.to_html).not_to include("Currently working with:")

        # Should not have any hidden fields for lead_provider_ids with actual values
        # (Rails includes an empty hidden field for checkbox arrays, so we check for fields with values)
        hidden_fields_with_values = result.css('input[name="lead_provider_ids[]"][type="hidden"]').select do |field|
          field["value"].present? && field["value"] != ""
        end
        expect(hidden_fields_with_values).to be_empty
      end
    end
  end
end
