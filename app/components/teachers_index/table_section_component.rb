module TeachersIndex
  class TableSectionComponent < ViewComponent::Base
    include GovukLinkHelper
    include Pagy::Frontend
    include Rails.application.routes.url_helpers
    include EmptyStateMessage

    def initialize(teachers:, pagy:, status:, query:)
      @teachers = teachers
      @pagy = pagy
      @status = status
      @query = query
    end

  private

    attr_reader :teachers, :pagy, :status, :query

    def teachers_present?
      teachers.any?
    end

    def teacher_full_name(teacher)
      Teachers::Name.new(teacher).full_name
    end

    def teacher_induction_start_date(teacher)
      Teachers::InductionPeriod.new(teacher).formatted_induction_start_date
    end

    def teacher_status_tag_kwargs(teacher)
      Teachers::InductionStatus.new(
        teacher:,
        induction_periods: teacher.induction_periods,
        trs_induction_status: teacher.trs_induction_status
      ).status_tag_kwargs
    end
  end
end
