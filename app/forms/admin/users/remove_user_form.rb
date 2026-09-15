module Admin
  module Users
    class RemoveUserForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :confirmed, :boolean
      attribute :user_name, :string

      validates :confirmed,
                acceptance: {
                  message: ->(form, _) { "Confirm you want to remove #{form.user_name} as a user" }
                },
                allow_nil: false
    end
  end
end
