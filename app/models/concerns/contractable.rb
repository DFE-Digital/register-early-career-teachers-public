module Contractable
  extend ActiveSupport::Concern

  included do
    has_one :contract, as: :contractable, touch: true, class_name: "CallOffContract"
  end
end
