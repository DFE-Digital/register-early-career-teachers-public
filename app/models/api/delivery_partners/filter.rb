class API::DeliveryPartners::Filter
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :cohort, :integer

  validates :cohort, numericality: { only_integer: true, greater_than: 2021 }
end
