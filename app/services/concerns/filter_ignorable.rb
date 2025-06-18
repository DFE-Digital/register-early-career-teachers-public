module FilterIgnorable
  extend ActiveSupport::Concern

  def ignore?(filter:)
    filter == :ignore || (!filter.nil? && filter.blank? && filter != false)
  end
end
