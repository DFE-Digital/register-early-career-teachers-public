class TimeTraveller
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :travel_to, :date

  validate :travel_to_valid

  def travel_to_date
    @travel_to_date ||= Schools::Validation::HashDate.new(travel_to)
  end

private

  def travel_to_valid
    return if travel_to_date.valid?

    errors.add(:travel_to, travel_to_date.error_message)
  end
end
