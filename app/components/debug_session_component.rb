# Testing utility to inspect session variables
class DebugSessionComponent < ApplicationComponent
  def render?
    Rails.application.config.enable_test_guidance && Current.session.present?
  end

  private

  def rows
    if Current.administrator.present?
      admin_rows + session_rows
    else
      session_rows
    end
  end

  def session_rows
    Current.session.map do |key, value|
      {key: {text: key.humanize}, value: {text: value}}
    end
  end

  def admin_rows
    [
      {
        key: {text: "Administrator"}, value: {text: Current.administrator.name}
      },
      {
        key: {text: "Role"}, value: {text: Current.role}
      }
    ]
  end
end
