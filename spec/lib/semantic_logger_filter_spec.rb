describe SemanticLoggerFilter do
  let(:log) { Struct.new(:name, :message, keyword_init: true) }

  it "allows ordinary log messages" do
    expect(SemanticLoggerFilter.call(log.new(name: "Teacher", message: "Teacher updated"))).to be(true)
  end

  it "excludes DfE Analytics events" do
    expect(SemanticLoggerFilter.call(log.new(name: "DfE::Analytics::SendEvents", message: "Sending events"))).to be(false)
    expect(SemanticLoggerFilter.call(log.new(name: "Analytics", message: "DfE::Analytics::SendEvents"))).to be(false)
  end

  it "excludes Solid Queue messages containing job arguments" do
    log_entry = log.new(name: "SolidQueue::Job", message: "Enqueued email with arguments: teacher@example.com")

    expect(SemanticLoggerFilter.call(log_entry)).to be(false)
  end

  it "excludes messages containing Solid Queue details from ordinary loggers" do
    log_entry = log.new(name: "Teacher", message: "SolidQueue job arguments: teacher@example.com")

    expect(SemanticLoggerFilter.call(log_entry)).to be(false)
  end

  it "allows Solid Queue failure and retry messages" do
    failure = log.new(name: "SolidQueue::Worker", message: "Failed to perform job: connection timed out")
    retrying = log.new(name: "SolidQueue::Worker", message: "Retrying job after connection timed out")

    expect(SemanticLoggerFilter.call(failure)).to be(true)
    expect(SemanticLoggerFilter.call(retrying)).to be(true)
  end
end
