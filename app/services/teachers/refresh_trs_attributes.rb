module Teachers
  # Service run after passing, failing, or reopening inductions,
  # and periodically, to sync attributes from TRS
  #
  # If a teacher record is not found in TRS but has an induction outcome we ensure
  # the status indicator is still accurate. eg: seed data
  class RefreshTRSAttributes
    include Manageable

    attr_reader :teacher, :api_client

    def initialize(teacher, api_client: TRS::APIClient.build)
      @teacher = teacher
      @api_client = api_client
    end

    # In the sandbox environment we don't want to allow data in TRS to
    # overwrite existing teacher data, so we skip the refresh.
    #
    # @return [Symbol] :refresh_disabled, :teacher_updated, :teacher_deactivated, :teacher_not_found
    def refresh!
      return :refresh_disabled unless enabled?

      update!
    rescue TRS::Errors::TeacherNotFound
      update_not_found!
    rescue TRS::Errors::TeacherMerged => e
      update_merged!(e.message)
    rescue TRS::Errors::TeacherDeactivated
      deactivate!
    end

    # @return [Boolean]
    def enabled?
      Rails.application.config.enable_trs_teacher_refresh
    end

  private

    # @raise [TRS::Errors::TeacherDeactivated, TRS::Errors::TeacherNotFound, TRS::Errors::TeacherMerged]
    # @return [TRS::Teacher]
    def trs_teacher
      @trs_teacher ||= api_client.find_teacher(trn: teacher.trn)
    end

    alias_method :trs_data, :trs_teacher

    # @return [Symbol]
    def update!
      Teacher.transaction do
        update_name!
        update_trs_induction_status!
        update_trs_attributes!

        :teacher_updated
      end
    end

    # @return [Symbol]
    def deactivate!
      Teacher.transaction do
        mark_teacher_as_deactivated!

        :teacher_deactivated
      end
    end

    # @return [Symbol]
    def update_not_found!
      Teacher.transaction do
        mark_teacher_as_not_found!

        :teacher_not_found
      end
    end

    # @param error_message [String] API redirect
    # @return [Symbol]
    def update_merged!(error_message)
      Teacher.transaction do
        mark_teacher_as_merged!(event_body: error_message)

        :teacher_merged
      end
    end
  end
end
