module Admin
  module Users
    class RemoveUserForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :confirmed, :boolean
      attr_accessor :user, :author

      validates :confirmed,
                acceptance: {
                  message: ->(form, _) { "Confirm you want to remove #{form.user.name} as a user" }
                },
                allow_nil: false

      def save
        return false unless valid?

        Admin::DfEUsers.new(author:).remove_user(user.id)
        true
      end
    end
  end
end
