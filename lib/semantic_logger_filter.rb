module SemanticLoggerFilter
  def self.call(log)
    name = log.name.to_s
    message = log.message.to_s
    solid_queue_message = name.include?("SolidQueue") || message.include?("SolidQueue")
    contains_job_arguments = message.match?(/\barguments?\s*[:=]/i)

    [
      name == "DfE::Analytics::SendEvents",
      message.include?("DfE::Analytics::SendEvents"),
      solid_queue_message && contains_job_arguments
    ].none?
  end
end
