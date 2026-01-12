module Teachers
  # Service run after passing, failing, or reopening inductions,
  # and periodically, to sync attributes from TRS
  #
  # Teacher records not found in TRS, like seed data, are also refreshed.
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
    # In some environments we use seeded teachers, which should not use
    # TRNs found in TRS, so we update only their status to mimic the real behaviour.
    #
    # @return [Symbol] :refresh_disabled, :teacher_updated, :teacher_deactivated, :teacher_not_found
    def refresh!
      return :refresh_disabled unless enabled?

      update!
    rescue TRS::Errors::TeacherNotFound
      update_not_found!
    rescue TRS::Errors::TeacherDeactivated
      deactivate!
    end

    # @return [Boolean]
    def enabled?
      Rails.application.config.enable_trs_teacher_refresh
    end

  private

    # @raise [TRS::Errors::TeacherDeactivated, TRS::Errors::TeacherNotFound]
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
  end
end
