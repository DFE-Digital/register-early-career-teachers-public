module UnclaimedIndex
  class BaseTableRowComponent < ApplicationComponent
    def initialize(row:, ect_at_school_period:)
      @row = row
      @ect_at_school_period = ect_at_school_period
    end

  private

    attr_reader :row, :ect_at_school_period

    delegate :trn, to: :ect_at_school_period, prefix: :teacher
    delegate :school_name, :school, :teacher, to: :ect_at_school_period
    delegate :induction_tutor_email, to: :school
    delegate :started_on, to: :ect_at_school_period, prefix: true

    def teacher_name
      Teachers::Name.new(ect_at_school_period.teacher).full_name
    end
  end
end
