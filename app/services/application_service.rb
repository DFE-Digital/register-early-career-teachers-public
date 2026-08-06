class ApplicationService
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.call(**kwargs) = new(**kwargs).call
end
