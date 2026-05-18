module FlashHelper
  def flash_alert_heading(alert = flash[:alert])
    alert.is_a?(Hash) ? alert["heading"] : alert
  end

  def flash_alert_body(alert = flash[:alert])
    alert.is_a?(Hash) ? alert["body"] : nil
  end
end
