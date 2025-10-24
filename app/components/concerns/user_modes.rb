# OPTIMIZE: We could pass the user session into components and derive the mode from that
# This could make sense before we start using finance and super admin logic
module UserModes
  class InvalidModeError < StandardError; end
  MODES = %i[admin appropriate_body school].freeze

  extend ActiveSupport::Concern

  included do
    attr_reader :mode
  end

  # @param mode [Symbol] :admin, :appropriate_body, or :school
  # @raise [UserModes::InvalidModeError] if mode is not recognised
  def initialize(*, mode:, **)
    raise(InvalidModeError) unless mode.in?(MODES)

    super()
    @mode = mode
  end

private

  # @return [Boolean]
  def admin_mode?
    mode == :admin
  end

  # @return [Boolean]
  def appropriate_body_mode?
    mode == :appropriate_body
  end

  # @return [Boolean]
  def school_mode?
    mode == :school
  end
end
