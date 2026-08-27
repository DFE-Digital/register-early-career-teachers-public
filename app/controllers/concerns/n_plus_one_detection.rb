module NPlusOneDetection
  extend ActiveSupport::Concern

  included do
    around_action :n_plus_one_detection if Rails.application.config.n_plus_one_detection_enabled
  end

private

  def n_plus_one_detection(&block)
    Prosopite.scan(&block)
  end
end
