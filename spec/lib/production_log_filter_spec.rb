require Rails.root.join("lib/production_log_filter")

RSpec.describe ProductionLogFilter do
  let(:log) { Struct.new(:name, :message, keyword_init: true) }

  it "allows ordinary log messages" do
    expect(described_class.call(log.new(name: "Teacher", message: "Teacher updated"))).to be(true)
  end

  it "excludes DfE Analytics events" do
    expect(described_class.call(log.new(name: "DfE::Analytics::SendEvents", message: "Sending events"))).to be(false)
    expect(described_class.call(log.new(name: "Analytics", message: "DfE::Analytics::SendEvents"))).to be(false)
  end

  it "excludes Solid Queue messages that may contain PII" do
    log_entry = log.new(name: "SolidQueue::Job", message: "Enqueued email: teacher@example.com")

    expect(described_class.call(log_entry)).to be(false)
  end
end
