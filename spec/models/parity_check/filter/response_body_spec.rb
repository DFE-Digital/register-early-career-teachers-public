describe ParityCheck::Filter::ResponseBody do
  let(:response) { FactoryBot.create(:parity_check_response) }
  let(:selected_key_paths) { [] }
  let(:instance) { described_class.new(response:, selected_key_paths:) }

  describe "attributes" do
    subject { instance }

    it { is_expected.to have_attributes(response:) }
    it { is_expected.to have_attributes(selected_key_paths:) }
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:ecf_body_hash).to(:response) }
    it { is_expected.to delegate_method(:rect_body_hash).to(:response) }
  end

  describe "#filterable?" do
    subject { instance }

    context "when the response body is not JSON" do
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body: "some text", rect_body: "some text") }

      it { is_expected.not_to be_filterable }
    end

    context "when at least one response body is JSON" do
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body: { some: :json }.to_json, rect_body: "some text") }

      it { is_expected.to be_filterable }
    end
  end

  describe "#filterable_key_hash" do
    subject(:key_hash) { instance.filterable_key_hash }

    context "when the bodies are nil" do
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body: nil, rect_body: nil) }

      it { is_expected.to be_empty }
    end

    context "when the bodies are not JSON" do
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body: "some text", rect_body: "some text") }

      it { is_expected.to be_empty }
    end

    context "when the bodies are JSON" do
      let(:ecf_body) { { key1: { subkey: "value" } }.to_json }
      let(:rect_body) { { key2: "value" }.to_json }
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body:, rect_body:) }

      it "returns a hash of the key structure" do
        expect(key_hash).to eq(
          key1: {
            subkey: {},
          },
          key2: {}
        )
      end

      context "when the JSON contains arrays of objects" do
        let(:ecf_body) { { key1: [{ subkey: "value1", other_subkey: [{ subsubkey: "value4" }] }, { subkey: "value2" }] }.to_json }
        let(:rect_body) { { key2: "value" }.to_json }

        it "returns a hash of the key structure with arrays" do
          expect(key_hash).to eq(
            key1: {
              subkey: {},
              other_subkey: {
                subsubkey: {}
              }
            },
            key2: {}
          )
        end
      end
    end
  end

  describe "#selected_key_paths=" do
    subject(:set_selected_key_paths) do
      instance.selected_key_paths = value
      instance.selected_key_paths
    end

    context "when the value is nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context "when the value is an array of strings" do
      let(:value) { ["key", "key subkey", "other_key"] }

      it { is_expected.to eq([%i[key], %i[key subkey], %i[other_key]]) }
    end

    context "when intermediate keys are not selected" do
      let(:value) { ["key subkey"] }

      it { expect { set_selected_key_paths }.to raise_error(ArgumentError, "Parent key path [:key] for key path [:key, :subkey] must also be selected.") }
    end

    context "when the value is a string" do
      let(:value) { "key" }

      it { is_expected.to eq([%i[key]]) }
    end

    context "when the values are not strings" do
      let(:value) { [123, 456] }

      it { is_expected.to eq([%i[123], %i[456]]) }
    end
  end

  describe "#selected?" do
    subject { instance.selected?(key_path) }

    let(:selected_key_paths) { ["key", "key subkey", "other", "other key"] }
    let(:key_path) { %i[key subkey] }

    context "when the key_path is selected (symbols)" do
      let(:key_path) { %i[key subkey] }

      it { is_expected.to be(true) }
    end

    context "when the key_path is selected (strings)" do
      let(:key_path) { %w[key subkey] }

      it { is_expected.to be(true) }
    end

    context "when the key_path is not selected" do
      let(:key_path) { %i[another_key] }

      it { is_expected.to be(false) }
    end

    context "when the selected_key_paths are nil" do
      let(:selected_key_paths) { nil }

      it { is_expected.to be(true) }
    end

    context "when the selected_key_paths are empty" do
      let(:selected_key_paths) { [] }

      it { is_expected.to be(false) }
    end
  end

  describe "#filtered_response" do
    subject(:filtered_response) { instance.filtered_response }

    let(:rect_body) { { key1: { subkey: [{ subsubkey: "value1" }] }, key2: "value2" }.to_json }
    let(:ecf_body) { { key3: { subkey: "value3" }, key4: "value4" }.to_json }
    let(:response) { FactoryBot.create(:parity_check_response, rect_body:, ecf_body:) }
    let(:selected_key_paths) { ["key1", "key1 subkey", "key1 subkey subsubkey", "key4"] }

    it "returns a response with filtered response bodies" do
      expect(filtered_response.rect_body).to eq(JSON.pretty_generate({ key1: { subkey: [{ subsubkey: "value1" }] } }))
      expect(filtered_response.ecf_body).to eq(JSON.pretty_generate({ key4: "value4" }))
    end

    context "when not filterable" do
      let(:response) { FactoryBot.create(:parity_check_response, ecf_body: "some text", rect_body: "some text") }

      it "does not change the response" do
        expect { filtered_response }.not_to(change(response, :attributes))
      end
    end

    context "when selected_key_paths is nil" do
      let(:selected_key_paths) { nil }

      it "does not change the response" do
        expect { filtered_response }.not_to(change(response, :attributes))
      end
    end
  end
end
