require Rails.root.join("lib/production_log_filter")

RSpec.describe ProductionLogFilter do
  Log = Struct.new(:name, :message, keyword_init: true)

  it "allows ordinary log messages" do
    expect(described_class.call(Log.new(name: "Teacher", message: "Teacher updated"))).to be(true)
  end

  it "excludes DfE Analytics events" do
    expect(described_class.call(Log.new(name: "DfE::Analytics::SendEvents", message: "Sending events"))).to be(false)
    expect(described_class.call(Log.new(name: "Analytics", message: "DfE::Analytics::SendEvents"))).to be(false)
  end

  it "excludes Solid Queue messages that may contain PII" do
    log = Log.new(name: "SolidQueue::Job", message: "Enqueued email: teacher@example.com")

    expect(described_class.call(log)).to be(false)
  end
end
