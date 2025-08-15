module DfEAnalytics
  module ActiveJobExtensions
    def serialize
      request_id = RequestLocals.fetch(:dfe_analytics_request_id) { nil } # rubocop:disable Style/RedundantFetchBlock
      Rails.logger.info("Serializing job with DfE Analytics request ID: #{request_id}")
      super.merge("dfe_analytics_request_id" => request_id)
    end

    def deserialize(job_data)
      request_id = job_data["dfe_analytics_request_id"]
      Rails.logger.info("Setting DfE Analytics request ID: #{request_id}")
      RequestLocals.store[:dfe_analytics_request_id] = request_id
      super(job_data)
    end
  end
end
