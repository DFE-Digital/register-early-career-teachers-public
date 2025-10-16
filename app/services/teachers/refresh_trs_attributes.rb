module Teachers
  # Service run after passing, failing, or reopening inductions,
  # and periodically, to sync attributes from TRS
  class RefreshTRSAttributes
    include Manageable

    attr_reader :teacher, :api_client

    def initialize(teacher, api_client: TRS::APIClient.build)
      @teacher = teacher
      @api_client = api_client
    end

    # In some environments (e.g. sandbox) we don't want to allow data in TRS to
    # overwrite existing teacher data, so we skip the refresh.
    #
    # @return [Symbol] :refresh_disabled, :teacher_updated, :teacher_deactivated
    def refresh!
      return :refresh_disabled unless enabled?

      update!
    rescue TRS::Errors::TeacherDeactivated
      deactivate!
    end

    # @return [Boolean]
    def enabled?
      Rails.application.config.enable_trs_teacher_refresh
    end

  private

    # @return [TRS::Teacher]
    def trs_teacher
      @trs_teacher ||= api_client.find_teacher(trn: teacher.trn)
    end

    alias_method :trs_data, :trs_teacher

    def update!
      Teacher.transaction do
        update_name!
        update_trs_induction_status!
        update_trs_attributes!

        :teacher_updated
      end
    end

    def deactivate!
      Teacher.transaction do
        mark_teacher_as_deactivated!

        :teacher_deactivated
      end
    end
  end
end
