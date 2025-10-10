RSpec.describe ImmutableOnceSetValidator, type: :model do
  subject { instance.tap(&:valid?).errors[:attribute] }

  let(:instance) { test_class.new(attribute: new_value, attribute_was: current_value) }
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :attribute, :attribute_was

      validates :attribute, immutable_once_set: true
    end
  end

  context "when attribute is `nil` and changing to `true`" do
    let(:current_value) { nil }
    let(:new_value) { true }

    it { is_expected.to be_empty }
  end

  context "when attribute is `nil` and changing to `nil`" do
    let(:current_value) { nil }
    let(:new_value) { nil }

    it { is_expected.to be_empty }
  end

  context "when attribute is `set` and changing to `set`" do
    let(:current_value) { "set" }
    let(:new_value) { "set" }

    it { is_expected.to be_empty }
  end

  context "when attribute is `false` and changing to `test`" do
    let(:current_value) { false }
    let(:new_value) { "test" }

    it { is_expected.to include("cannot be changed once set") }
  end

  context "when the attribute is `` and is changing to `true`" do
    let(:current_value) { "" }
    let(:new_value) { true }

    it { is_expected.to include("cannot be changed once set") }
  end

  context "when the attribute is `true` and is changing to `false`" do
    let(:current_value) { true }
    let(:new_value) { false }

    it { is_expected.to include("cannot be changed once set") }
  end

  context "when the attribute is `true` and is changing to `nil`" do
    let(:current_value) { true }
    let(:new_value) { nil }

    it { is_expected.to include("cannot be changed once set") }
  end
end
