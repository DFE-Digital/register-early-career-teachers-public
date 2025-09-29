class DebugSessionComponent < ApplicationComponent
  attr_reader :current_session, :current_user

  # @param current_session [Hash, nil]
  # @param current_user [Sessions::User]
  def initialize(current_session:, current_user:)
    @current_session = Hash(current_session)
    @current_user = current_user
  end

  def render?
    Rails.env.development? && current_session.present?
  end

private

  def details
    govuk_summary_list(rows:)
  end

  def rows
    current_session.map { |key, value|
      { key: { text: key.humanize }, value: { text: value } }
    } << role_info
  end

  def role_info
    { key: { text: 'Role' }, value: { text: role } }
  end

  def role
    ::User::ROLES[current_user.user.role.to_sym]
  end
end
