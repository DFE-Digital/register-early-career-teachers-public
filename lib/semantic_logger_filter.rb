module SemanticLoggerFilter
  def self.call(log)
    name = log.name.to_s
    message = log.message.to_s

    return false if name == "DfE::Analytics::SendEvents"
    return false if message.include?("DfE::Analytics::SendEvents")
    return true unless name.include?("SolidQueue") || message.include?("SolidQueue")
    return false if message.match?(/\barguments?\s*[:=]/i)

    payload = log.respond_to?(:payload) ? log.payload : nil
    return true unless payload.is_a?(Hash)

    logged_arguments = payload[:arguments] || payload["arguments"]
    logged_arguments.blank? || logged_arguments == "[]"
  end
end
