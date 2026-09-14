class API::Pagination
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :page, :integer, default: 1
  attribute :per_page, :integer, default: 20

  validates :page,
            numericality: { only_integer: true, greater_than: 0 }

  validates :per_page,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 100
            }
end
