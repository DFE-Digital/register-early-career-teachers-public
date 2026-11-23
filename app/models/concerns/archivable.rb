module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where(archived: true) }
    scope :unarchived, -> { where(archived: false) }
  end

  def archive!
    update!(archived: true) unless archived?
  end
end
