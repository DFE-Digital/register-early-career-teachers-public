module Admin
  module Users
    class RemoveUserForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :confirmed, :boolean
      attribute :user_name, :string

      validates :confirmed, acceptance: {
        message: ->(object, _) { "Confirm you want to remove #{object.user_name} as a user" }
      }
    end
  end
end
