module UnclaimedIndex
  class TableSectionComponent < ApplicationComponent
    include Pagy::Frontend
    include Rails.application.routes.url_helpers

    def initialize(ect_at_school_periods:, pagy:, row_component:)
      @ect_at_school_periods = ect_at_school_periods
      @pagy = pagy
      @row_component = row_component
    end

  private

    attr_reader :ect_at_school_periods, :pagy, :row_component
  end
end
