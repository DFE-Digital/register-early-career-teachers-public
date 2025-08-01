RSpec.describe ParityCheckHelper, type: :helper do
  describe "#grouped_endpoints" do
    subject(:grouping) { helper.grouped_endpoints(endpoints) }

    let(:endpoints) do
      [
        FactoryBot.build(:parity_check_endpoint, path: "/api/v1/users"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v3/users/create"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v2/participant-declarations"),
        FactoryBot.build(:parity_check_endpoint, path: "/login"),
      ]
    end

    it "groups endpoints by their group name, in ascending order" do
      expect(grouping.to_a).to eq([
        [:miscellaneous, [endpoints[3]]],
        [:"participant-declarations", [endpoints[2]]],
        [:users, endpoints[0..1]],
      ])
    end
  end

  describe "#grouped_requests" do
    subject(:grouping) { helper.grouped_requests(requests) }

    let(:requests) do
      [
        FactoryBot.build(:parity_check_request, endpoint: FactoryBot.build(:parity_check_endpoint, path: "/api/v1/users")),
        FactoryBot.build(:parity_check_request, endpoint: FactoryBot.build(:parity_check_endpoint, path: "/api/v3/users/create")),
        FactoryBot.build(:parity_check_request, endpoint: FactoryBot.build(:parity_check_endpoint, path: "/api/v2/participant-declarations")),
        FactoryBot.build(:parity_check_request, endpoint: FactoryBot.build(:parity_check_endpoint, path: "/login")),
      ]
    end

    it "groups requests by their endpoint's group name, in ascending order" do
      expect(grouping.to_a).to eq([
        [:miscellaneous, [requests[3]]],
        [:"participant-declarations", [requests[2]]],
        [:users, requests[0..1]],
      ])
    end
  end

  describe "#formatted_endpoint_group_name" do
    subject { helper.formatted_endpoint_group_name(:"participant-declarations") }

    it { is_expected.to eq("Participant declarations") }
  end

  describe "#formatted_endpoint_group_names" do
    subject { helper.formatted_endpoint_group_names(run) }

    let(:run) { FactoryBot.build(:parity_check_run) }

    before { allow(run).to receive(:request_group_names).and_return(%i[participant-declarations users]) }

    it { is_expected.to eq(%(<ul class=\"govuk-list\"><li>Participant declarations</li><li>Users</li></ul>)) }
  end

  describe "#match_rate_tag" do
    {
      0 => "red",
      49 => "red",
      50 => "orange",
      74 => "orange",
      75 => "yellow",
      99 => "yellow",
      100 => "green"
    }.each do |match_rate, colour|
      context "when match rate is #{match_rate}%" do
        subject { helper.match_rate_tag(match_rate) }

        it { is_expected.to eq(%(<strong class=\"govuk-tag govuk-tag--#{colour}\">#{match_rate}%</strong>)) }
      end
    end
  end

  describe "#status_code_tag" do
    {
      0 => "green",
      299 => "green",
      300 => "yellow",
      399 => "yellow",
      400 => "red",
    }.each do |status_code, colour|
      context "when status code is #{status_code}%" do
        subject { helper.status_code_tag(status_code) }

        it { is_expected.to eq(%(<strong class=\"govuk-tag govuk-tag--#{colour}\">#{status_code}</strong>)) }
      end
    end
  end

  describe "#comparison_emoji" do
    subject { helper.comparison_emoji(matching) }

    context "when matching" do
      let(:matching) { true }

      it { is_expected.to eq("✅") }
    end

    context "when different" do
      let(:matching) { false }

      it { is_expected.to eq("❌") }
    end
  end

  describe "#performance_gain" do
    subject { helper.performance_gain(ratio) }

    context "when the ratio is nil" do
      let(:ratio) { nil }

      it { is_expected.to be_nil }
    end

    context "when the ratio is 1" do
      let(:ratio) { 1 }

      it { is_expected.to eq("⚖️ equal") }
    end

    context "when the ratio is greater than 0" do
      let(:ratio) { 2.5 }

      it { is_expected.to eq("🚀 2.5x faster") }
    end

    context "when the ratio is less than 0" do
      let(:ratio) { -3.0 }

      it { is_expected.to eq("🐌 3x slower") }
    end
  end

  describe "#run_mode_options" do
    subject(:options) { run_mode_options }

    it "returns an array of mode options with value, name, and description" do
      expect(options).to contain_exactly(
        have_attributes(value: :concurrent, name: "Concurrent", description: "Send requests in parallel for a faster run."),
        have_attributes(value: :sequential, name: "Sequential", description: "Send requests one at a time for accurate performance benchmarking.")
      )
    end
  end

  describe "#comparison_in_words" do
    subject { helper.comparison_in_words(matching) }

    context "when matching" do
      let(:matching) { true }

      it { is_expected.to eq("the same") }
    end

    context "when different" do
      let(:matching) { false }

      it { is_expected.to eq("different") }
    end
  end

  describe "#sanitize_diff" do
    subject { helper.sanitize_diff(html) }

    let(:html) { response.body_diff.to_s(:html) }
    let(:ecf_body) { { key1: { subkey: "value1" } }.to_json }
    let(:rect_body) { { key1: { subkey: "value2" } }.to_json }
    let(:response) { FactoryBot.build(:parity_check_response, rect_body:, ecf_body:) }

    it { is_expected.to eq(CGI.unescapeHTML(html.html_safe)) }

    context "when the diff contains malicious HTML" do
      let(:html) { "<script>alert('maliciousness');</script>#{response.body_diff.to_s(:html)}" }

      it { is_expected.not_to include("<script>") }
    end
  end

  describe "#render_filterable_key_hash" do
    let(:key_hash) do
      {
        key1: {
          key2: {}
        },
        key3: {}
      }
    end

    it "renders a nested list of the key hash, yielding the key name and keypath of each" do
      rendered_list = helper.render_filterable_key_hash(key_hash) do |key_path|
        key_path.join(".")
      end

      # Embedding the nested ul inside the li for the parent key
      # makes the CSS for rendering the 'tree' connections much simpler.
      expected_html = <<~HTML
        <ul class="govuk-list">
          <li>key1
            <ul class="govuk-list">
              <li>key1.key2</li>
            </ul>
          </li>
          <li>key3</li>
        </ul>
      HTML

      expect(rendered_list).to eq(expected_html.squish.gsub(/\s+</, "<"))
    end
  end
end
