module Migration
  class Base < ApplicationRecord
    self.abstract_class = true

    connects_to database: { reading: :legacy, writing: :legacy } if Rails.env.migration? || Rails.env.development?
    connects_to database: { reading: :ecf, writing: :ecf } if Rails.env.test?

    def readonly?
      !Rails.env.test? # allow factories in test
    end
  end
end
