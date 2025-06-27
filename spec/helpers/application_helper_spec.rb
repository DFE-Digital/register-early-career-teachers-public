RSpec.describe ApplicationHelper, type: :helper do
  include GovukVisuallyHiddenHelper
  include GovukLinkHelper
  include GovukComponentsHelper
  include TitleWithErrorPrefixHelper

  describe "#page_data" do
    it "sets the title to the provided value" do
      page_data(title: "Some title")

      expect(content_for(:page_title)).to eql("Some title")
    end

    it "prefixes title with 'Error:' when there's an error present" do
      page_data(title: "Some title", error: true)

      expect(content_for(:page_title)).to eq('Error: Some title')
    end

    describe "backlink and breadcrumbs" do
      it "adds a backlink using the backlink_href" do
        page_data(backlink_href: "/retreat", title: 'Back link test')

        expect(content_for(:backlink_or_breadcrumb)).to eq(%(<a class="govuk-back-link" href="/retreat">Back</a>))
      end

      it "adds provided breadcrumbs" do
        page_data(title: "Breadcrumb test", breadcrumbs: { "Home" => "/", "Detail" => "/detail" })

        expect(content_for(:backlink_or_breadcrumb)).to eq(
          <<~HTML.chomp
            <div class="govuk-breadcrumbs">
              <ol class="govuk-breadcrumbs__list">
                  <li class="govuk-breadcrumbs__list-item"><a class="govuk-breadcrumbs__link" href="/">Home</a></li>
                  <li class="govuk-breadcrumbs__list-item"><a class="govuk-breadcrumbs__link" href="/detail">Detail</a></li>
              </ol>
            </div>
          HTML
        )
      end
    end

    describe "page_header" do
      it "wraps the header in a h1 with govuk-heading-l" do
        page_data(title: "Some title", header: "Some header")

        expect(content_for(:page_header)).to eq(%(<h1 class="govuk-heading-l">Some header</h1>))
      end

      context "when no header is provided" do
        it "sets the header to the title value" do
          page_data(title: "Some title")

          expect(content_for(:page_header)).to eq(%(<h1 class="govuk-heading-l">Some title</h1>))
        end
      end

      context "when header is set to false" do
        it "sets the page_header to nil" do
          page_data(title: "Some title")

          expect(content_for(:page_header)).to eq(%(<h1 class="govuk-heading-l">Some title</h1>))
        end
      end

      context "when the header size is overridden" do
        it "has the appropriate govuk size class" do
          page_data(title: "Some title", header: "Some header", header_size: "m")

          expect(content_for(:page_header)).to eq(%(<h1 class="govuk-heading-m">Some header</h1>))
        end
      end

      context "when the header has a caption" do
        it 'sets the heading caption to the provided value with the default size m' do
          page_data(title: "Some title", caption: 'Some caption')

          expect(content_for(:page_caption)).to eq('<span class="govuk-caption-m">Some caption</span>')
        end

        context 'when the caption size is overridden' do
          it 'sets the heading caption to the provided value with the provided size' do
            page_data(title: "Some title", caption: 'Some caption', caption_size: 'l')

            expect(content_for(:page_caption)).to eq('<span class="govuk-caption-l">Some caption</span>')
          end
        end
      end

      context 'when the caption is specified without a header' do
        it 'sets no caption' do
          page_data(title: nil, caption: 'Some caption')

          expect(content_for(:page_caption)).to be_nil
        end
      end

      context 'when extra page header classes are provided' do
        it 'adds the extra classes to the existing one' do
          page_data(title: "Some title", header: "Some header", header_classes: 'extra')

          expect(content_for(:page_header)).to eq(%(<h1 class="govuk-heading-l extra">Some header</h1>))
        end
      end
    end
  end

  describe "#backlink_with_fallback" do
    let(:mock_referer) { "http://example.com/referer" }
    let(:mock_url) { "http://example.com/url" }

    before do
      mock_request = instance_double(ActionDispatch::Request, referer: mock_referer, url: mock_url)
      allow(self).to receive(:request).and_return(mock_request)
    end

    context "request with referer" do
      it "returns referer url" do
        url = backlink_with_fallback(fallback: "/statements")
        expect(url).to eq(mock_referer)
      end

      context "when referer url is same as page url" do
        let(:mock_referer) { mock_url }

        it "returns fallback url" do
          url = backlink_with_fallback(fallback: "/statements")
          expect(url).to eq("/statements")
        end
      end
    end

    context "request without referer" do
      let(:mock_referer) { nil }

      it "returns fallback url" do
        url = backlink_with_fallback(fallback: "/statements")
        expect(url).to eq("/statements")
      end
    end
  end

  describe "#page_data_from_front_matter" do
    context "with yaml content" do
      let(:front_matter) do
        <<~FRONT_MATTER
          ---
          title: Some title
          header: Some header
          ---
          ignored content
        FRONT_MATTER
      end

      it "calls page_data with the provided front matter content" do
        allow(self).to receive(:page_data)

        page_data_from_front_matter(front_matter)

        expect(self).to have_received(:page_data).with(title: "Some title", header: "Some header")
      end
    end

    context "handles empty content" do
      let(:front_matter) { "" }

      it "returns nil" do
        allow(self).to receive(:page_data)

        page_data_from_front_matter(front_matter)

        expect(self).not_to have_received(:page_data)
      end
    end
  end

  describe '#support_mailto_link' do
    it 'returns a govuk styled link to the CPD support email address' do
      expect(support_mailto_link).to have_css(
        %(a[href='mailto:teacher.induction@education.gov.uk'][class='govuk-link']),
        text: 'teacher.induction@education.gov.uk'
      )
    end

    context 'when custom text is passed in' do
      it 'adds the custom text into the link' do
        expect(support_mailto_link('feedback')).to have_css(
          %(a[href='mailto:teacher.induction@education.gov.uk'][class='govuk-link']),
          text: 'feedback'
        )
      end
    end
  end

  describe '#smart_quotes' do
    it 'converts straight single quotes to smart single quotes' do
      expect(helper.smart_quotes("It's a test")).to eq("It’s a test")
    end

    it 'converts straight double quotes to smart double quotes' do
      expect(helper.smart_quotes('"Hello"')).to eq('“Hello”')
    end

    it 'does not alter text without quotes' do
      expect(helper.smart_quotes("Just some plain text")).to eq("Just some plain text")
    end

    it 'handles mixed quotes correctly' do
      expect(helper.smart_quotes(%q('Hello' "world"))).to eq("‘Hello’ “world”")
    end

    it 'returns nil if input is nil' do
      expect(helper.smart_quotes(nil)).to be_nil
    end

    it 'returns an empty string if input is blank' do
      expect(helper.smart_quotes("")).to eq("")
    end
  end

  describe '#boolean_to_yes_or_no' do
    subject { boolean_to_yes_or_no(value) }

    context 'when value is true' do
      let(:value) { true }

      it { is_expected.to eql('Yes') }
    end

    context 'when value is false' do
      let(:value) { false }

      it { is_expected.to eql('No') }
    end
  end

  describe '#govuk_html_element' do
    subject { govuk_html_element { content } }

    let(:content) { 'what a nice page' }

    it 'renders the provided content in a HTML element' do
      expect(subject).to match(%r{<html.*#{content}</html>})
    end

    it 'includes both the govuk-template and govuk-template--rebranded classes' do
      expect(subject).to include('govuk-template govuk-template--rebranded')
    end

    it 'defaults to english' do
      expect(subject).to include('lang="en"')
    end
  end
end
