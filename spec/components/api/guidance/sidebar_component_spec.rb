RSpec.describe API::Guidance::SidebarComponent, type: :component do
  describe "initialization" do
    subject(:component) { described_class.new(current_path:, page:) }

    let(:current_path) { nil }
    let(:page) { nil }

    let(:mock_files) { %w[alpha_page.md beta_page.md gamma_page.md] }
    let(:mock_frontmatter) do
      {
        "alpha_page.md" => { "title" => "Alpha Page", "sidebar_title" => "Alpha", "sidebar_position" => 2 },
        "beta_page.md" => { "title" => "Beta Page", "sidebar_position" => 1 },
        "gamma_page.md" => { "title" => "Gamma Page" }
      }
    end

    before do
      allow(Dir).to receive(:glob).with(described_class::GUIDANCE_DIR).and_return(mock_files)
      mock_files.each do |file|
        allow(described_class).to receive(:extract_frontmatter).with(file).and_return(mock_frontmatter[file])
      end
    end

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
      it "returns one entry per markdown file" do
        pages = described_class.guidance_pages
        expect(pages.length).to eq(mock_files.length)
      end

      it "orders pages by sidebar_position" do
        pages = described_class.guidance_pages
        positions = pages.map { |p| p[:sidebar_position] }
        expect(positions).to eq(positions.sort)
      end

      it "positions pages without sidebar_position last" do
        pages = described_class.guidance_pages
        expect(pages.map { |p| p[:title] }).to eq(["Beta Page", "Alpha", "Gamma Page"])
      end

      it "uses sidebar_title when present" do
        pages = described_class.guidance_pages
        alpha = pages.find { |p| p[:path] == "alpha-page" }
        expect(alpha[:title]).to eq("Alpha")
      end

      it "falls back to title when sidebar_title is not set" do
        pages = described_class.guidance_pages
        beta = pages.find { |p| p[:path] == "beta-page" }
        expect(beta[:title]).to eq("Beta Page")
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
      let(:current_path) { "/api/guidance/guidance-for-lead-providers/beta-page" }
      let(:page) { "guidance-for-lead-providers/beta-page" }

      it "returns one node per guidance page" do
        render_inline(component)

        expect(component.structure.length).to eq(mock_files.length)
      end

      it "returns nodes with correct attributes" do
        render_inline(component)

        component.structure.each do |node|
          expect(node.name).to be_present
          expect(node.href).to start_with("/api/guidance/guidance-for-lead-providers/")
          expect(node.prefix).to eq(node.href)
          expect(node.nodes).to eq([])
        end
      end
    end

    describe "#render" do
      let(:current_path) { "/api/guidance/guidance-for-lead-providers/beta-page" }
      let(:page) { "guidance-for-lead-providers/beta-page" }

      it "renders links for guidance pages" do
        render_inline(component)

        expect(rendered_content).to have_link("Beta Page")
        expect(rendered_content).to have_link("Alpha")
        expect(rendered_content).to have_link("Gamma Page")
      end
    end
  end
end
