module ProductionLogFilter
  def self.call(log)
    name = log.name.to_s
    message = log.message.to_s

    !(
      name == "DfE::Analytics::SendEvents" ||
      message.include?("DfE::Analytics::SendEvents") ||
      name.include?("SolidQueue") ||
      message.include?("SolidQueue")
    )
  end
end
