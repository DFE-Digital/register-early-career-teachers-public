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

    describe ".guidance_pages" do
      let(:md_files) { Dir.glob(described_class::GUIDANCE_DIR) }

      it "returns one entry per markdown file" do
        pages = described_class.guidance_pages
        expect(pages.length).to eq(md_files.length)
      end

      it "orders pages by sidebar_position" do
        pages = described_class.guidance_pages
        positions = pages.map { |p| p[:sidebar_position] }
        expect(positions).to eq(positions.sort)
      end

      it "positions pages without sidebar_position last" do
        allow(Dir).to receive(:glob).with(described_class::GUIDANCE_DIR).and_return(
          %w[a.md b.md c.md]
        )
        allow(described_class).to receive(:extract_frontmatter).with("a.md").and_return("title" => "A", "sidebar_position" => 2)
        allow(described_class).to receive(:extract_frontmatter).with("b.md").and_return("title" => "B")
        allow(described_class).to receive(:extract_frontmatter).with("c.md").and_return("title" => "C", "sidebar_position" => 1)

        pages = described_class.guidance_pages

        expect(pages.map { |p| p[:title] }).to eq(%w[C A B])
      end

      it "uses sidebar_title when present" do
        allow(Dir).to receive(:glob).with(described_class::GUIDANCE_DIR).and_return(%w[a.md])
        allow(described_class).to receive(:extract_frontmatter).with("a.md")
          .and_return("title" => "Full Title", "sidebar_title" => "Short", "sidebar_position" => 1)

        pages = described_class.guidance_pages

        expect(pages.first[:title]).to eq("Short")
      end

      it "falls back to title when sidebar_title is not set" do
        allow(Dir).to receive(:glob).with(described_class::GUIDANCE_DIR).and_return(%w[a.md])
        allow(described_class).to receive(:extract_frontmatter).with("a.md")
          .and_return("title" => "Full Title", "sidebar_position" => 1)

        pages = described_class.guidance_pages

        expect(pages.first[:title]).to eq("Full Title")
      end

      it "derives path from filename with hyphens" do
        pages = described_class.guidance_pages
        pages.each do |page|
          expect(page[:path]).not_to include("_")
          expect(page[:path]).not_to end_with(".md")
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
