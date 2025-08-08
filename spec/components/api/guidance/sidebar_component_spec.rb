RSpec.describe API::Guidance::SidebarComponent, type: :component do
  describe "initialization" do
    subject(:component) { described_class.new(current_path:, page:) }

    let(:current_path) { nil }
    let(:page) { nil }

    describe "#render?" do
      ["guidance-for-lead-providers", "guidance-for-lead-providers/test-1"].each do |guidance_page|
        context "when guidance page is '#{guidance_page}'" do
          let(:page) { guidance_page }

          it "renders component" do
            expect(component.render?).to be(true)
          end
        end
      end

      [nil, "", "sandbox", "release-notes/test-1"].each do |guidance_page|
        context "when guidance page is '#{guidance_page}'" do
          let(:page) { guidance_page }

          it "does not render component" do
            expect(component.render?).to be(false)
          end
        end
      end
    end

    describe "#structure" do
      it "returns guidance pages in correct node format" do
        render_inline(component)
        structure = component.structure

        expect(structure[0].name).to eq("API IDs explained")
        expect(structure[0].href).to eq("/api/guidance/guidance-for-lead-providers/api-ids-explained")
        expect(structure[0].prefix).to eq("/api/guidance/guidance-for-lead-providers/api-ids-explained")
        expect(structure[0].nodes).to eq([])

        expect(structure[1].name).to eq("API data states")
        expect(structure[1].href).to eq("/api/guidance/guidance-for-lead-providers/api-data-states")
        expect(structure[1].prefix).to eq("/api/guidance/guidance-for-lead-providers/api-data-states")
        expect(structure[1].nodes).to eq([])
      end
    end

    describe "#render" do
      let(:current_path) { "/api/guidance/guidance-for-lead-providers/api-data-states" }
      let(:page) { "guidance-for-lead-providers/api-data-states" }

      it "renders the component" do
        render_inline(component)

        expect(rendered_content).to have_link("API data states")
      end
    end
  end
end
