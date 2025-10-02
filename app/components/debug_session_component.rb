# Testing utility to inspect session variables
class DebugSessionComponent < ApplicationComponent
  attr_reader :current_session, :current_user

  # @param current_session [Hash, nil]
  # @param current_user [Sessions::User, nil]
  def initialize(current_session:, current_user:)
    @current_session = Hash(current_session)
    @current_user = current_user
  end

  def render?
    Rails.application.config.enable_test_guidance && current_session.present?
  end

private

  def details
    govuk_summary_list(rows: session_rows << role_row)
  end

  def session_rows
    current_session.map do |key, value|
      { key: { text: key.humanize }, value: { text: value } }
    end
  end

  def role_row
    { key: { text: 'Role' }, value: { text: role_name } }
  end

  def role_name
    return 'N/A' unless current_user&.dfe_user?

    ::User::ROLES[current_user.user.role.to_sym]
  end
end
