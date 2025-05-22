RSpec.describe ApplicationHelper, type: :helper do
  include GovukVisuallyHiddenHelper
  include GovukLinkHelper
  include TitleWithErrorPrefixHelper

  describe "#page_data" do
    it "sets the title to the provided value" do
      expect(page_data(title: "Some title").fetch(:page_title)).to eq('Some title')
    end

    it "prefixes title with 'Error:' when there's an error present" do
      expect(page_data(title: "Some title", error: true).fetch(:page_title)).to eq('Error: Some title')
    end

    it "wraps the header in a h1 with govuk-heading-l" do
      expect(page_data(title: "Some title", header: "Some header").fetch(:page_header)).to eq(%(<h1 class="govuk-heading-l">Some header</h1>))
    end

    context "when no header is provided" do
      it "sets the header to the title value" do
        expect(page_data(title: "Some title").fetch(:page_header)).to eq(%(<h1 class="govuk-heading-l">Some title</h1>))
      end
    end

    it "allows the title size to be overridden" do
      expect(page_data(title: "Some title", header: "Some header", header_size: "m").fetch(:page_header)).to eq(%(<h1 class="govuk-heading-m">Some header</h1>))
    end

    it 'sets the heading caption to the provided value with the default size m' do
      expect(page_data(title: "Some title", caption: 'Some caption').fetch(:page_caption)).to eq('<span class="govuk-caption-m">Some caption</span>')
    end

    context 'when the caption size is overridden' do
      it 'sets the heading caption to the provided value with the provided size' do
        expect(page_data(title: "Some title", caption: 'Some caption', caption_size: 'l').fetch(:page_caption)).to eq('<span class="govuk-caption-l">Some caption</span>')
      end
    end

    context 'when extra page header classes are provided' do
      it 'adds the extra classes to the existing one' do
        expect(page_data(title: "Some title", header: "Some header", header_classes: 'extra').fetch(:page_header)).to eq(%(<h1 class="govuk-heading-l extra">Some header</h1>))
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
end
