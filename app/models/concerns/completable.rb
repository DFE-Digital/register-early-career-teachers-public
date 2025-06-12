module Completable
  extend ActiveSupport::Concern

  included do
    validates :started_at, presence: true, if: :completed_at?
    validates :completed_at, comparison: { greater_than_or_equal_to: :started_at }, allow_nil: true
  end
end
