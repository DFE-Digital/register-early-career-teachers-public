class Current < ActiveSupport::CurrentAttributes
  attribute :session, default: {}
  attribute :user,
            :administrator,
            :role,
            :time_travelled_date

  def user=(user)
    super
    self.administrator = user&.user
    self.role = ::User::ROLES[administrator.role.to_sym] if administrator
  end
end
