class API::ThirdParty < ApplicationRecord
  self.table_name = :api_third_parties

  has_many :api_tokens, class_name: "API::Token"

  validates :name, presence: { message: "Business name" }
  validates :email, presence: { message: "Contact details" }
end
