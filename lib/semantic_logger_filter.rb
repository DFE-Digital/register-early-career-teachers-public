module SemanticLoggerFilter
  def self.call(log)
    name = log.name.to_s
    message = log.message.to_s
    solid_queue_message = name.include?("SolidQueue") || message.include?("SolidQueue")
    payload = log.respond_to?(:payload) ? log.payload : nil
    contains_job_arguments = message.match?(/\barguments?\s*[:=]/i) ||
      (payload.is_a?(Hash) && (payload.key?(:arguments) || payload.key?("arguments")))

    [
      name == "DfE::Analytics::SendEvents",
      message.include?("DfE::Analytics::SendEvents"),
      solid_queue_message && contains_job_arguments
    ].none?
  end
end
