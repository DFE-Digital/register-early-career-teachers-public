module Admin
  module Finance
    class AuthorisePaymentForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :confirmed, :boolean

      validates :confirmed, acceptance: { message: "You must have completed all assurance checks", allow_nil: false }
    end
  end
end
