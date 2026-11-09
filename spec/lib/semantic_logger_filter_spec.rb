describe SemanticLoggerFilter do
  let(:log) { Struct.new(:name, :message, :payload, keyword_init: true) }

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

  it "excludes ActiveJob arguments in the structured payload" do
    log_entry = log.new(
      name: "ActiveJob",
      message: "Enqueued ExampleJob (Job ID: job-id) to SolidQueue(default)",
      payload: { job_class: "ExampleJob", arguments: JSON.pretty_generate(["teacher@example.com"]) }
    )

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

  [
    ["argument logging is disabled", ""],
    ["the job has no arguments", "[]"]
  ].each do |description, arguments|
    context "when #{description}" do
      it "allows ActiveJob failure and retry entries with a structured payload" do
        failure = log.new(
          name: "ActiveJob",
          message: "Error performing GIASImportJob (Job ID: job-id) to SolidQueue(default) in 12.3ms",
          payload: { job_class: "GIASImportJob", arguments: }
        )
        retrying = log.new(
          name: "ActiveJob",
          message: "Retrying GIASImportJob (Job ID: job-id) to SolidQueue(default) after 2 attempts in 30 seconds, due to a Net::ReadTimeout (Net::ReadTimeout).",
          payload: { job_class: "GIASImportJob", executions: 2, wait: 30, arguments: }
        )

        expect(SemanticLoggerFilter.call(failure)).to be(true)
        expect(SemanticLoggerFilter.call(retrying)).to be(true)
      end
    end
  end

  it "excludes ActiveJob retry entries when arguments are logged" do
    retrying = log.new(
      name: "ActiveJob",
      message: "Retrying ExampleJob (Job ID: job-id) to SolidQueue(default) after 2 attempts in 30 seconds.",
      payload: { "job_class" => "ExampleJob", "arguments" => JSON.pretty_generate(["teacher@example.com"]) }
    )

    expect(SemanticLoggerFilter.call(retrying)).to be(false)
  end
end
