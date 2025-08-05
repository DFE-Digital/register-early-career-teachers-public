RSpec.describe Admin::SelectLeadProvidersFormComponent, type: :component do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:year) { 2025 }
  let(:page) { "2" }
  let(:q) { "search" }

  let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider One") }
  let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider Two") }
  let(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider Three") }

  let(:contract_period) { FactoryBot.create(:contract_period, year:, started_on: 1.month.from_now, finished_on: 2.months.from_now) }
  let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }
  let(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_3, contract_period:) }

  let(:current_partnerships) do
    [
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_1)
    ]
  end

  let(:component) do
    described_class.new(
      delivery_partner:,
      contract_period:,
      current_partnerships:,
      year:,
      page:,
      q:
    )
  end

  describe "component logic and methods" do
    describe "#all_lead_providers_for_period" do
      it "returns all active lead providers for the contract period" do
        providers = component.send(:all_lead_providers_for_period)
        expect(providers).to contain_exactly(active_lead_provider_1, active_lead_provider_2, active_lead_provider_3)
      end
    end

    describe "#currently_selected_ids" do
      it "returns string array of active lead provider IDs" do
        ids = component.send(:currently_selected_ids)
        expect(ids).to eq([active_lead_provider_1.id.to_s])
      end
    end

    describe "#legend_text" do
      it "returns correct legend text" do
        expect(component.send(:legend_text)).to eq("Select lead providers")
      end
    end

    describe "#hint_text" do
      it "returns correct hint text" do
        hint = component.send(:hint_text)
        expect(hint).to include("Test Delivery Partner")
        expect(hint).to include("2025")
        expect(hint).to include("Select lead providers that should work")
      end
    end

    describe "#selected?" do
      it "returns true when active lead provider is currently selected" do
        expect(component.send(:selected?, active_lead_provider_1)).to be true
      end

      it "returns false when active lead provider is not currently selected" do
        expect(component.send(:selected?, active_lead_provider_2)).to be false
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
            contract_period:,
            current_partnerships:,
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
        contract_period:,
        current_partnerships: [],
        year:,
        page:,
        q:
      )
      expect { render_inline(component_without_partnerships) }.not_to raise_error
    end
  end
end
