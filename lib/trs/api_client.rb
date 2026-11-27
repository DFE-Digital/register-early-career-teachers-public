module TRS
  class APIClient
    QUERY_PARAMS = HttpAPIClient::QUERY_PARAMS

    # Kept for backwards compatibility with existing callers/stubs
    def self.build = new

    def find_teacher(trn:, **)              = client_for(trn).find_teacher(trn:, **)
    def begin_induction!(trn:, **)          = client_for(trn).begin_induction!(trn:, **)
    def pass_induction!(trn:, **)           = client_for(trn).pass_induction!(trn:, **)
    def fail_induction!(trn:, **)           = client_for(trn).fail_induction!(trn:, **)
    def reset_teacher_induction!(trn:, **)  = client_for(trn).reset_teacher_induction!(trn:, **)
    def reopen_teacher_induction!(trn:, **) = client_for(trn).reopen_teacher_induction!(trn:, **)

  private

    def client_for(trn)
      return real_client unless use_fake_client?(trn)

      Rails.logger.warn("Using TRS::FakeAPIClient for TRN #{trn}")

      fake_client
    end

    def use_fake_client?(trn)
      return false if Rails.env.production?
      return true if Rails.application.config.enable_fake_trs_api

      # when ENABLE_FAKE_TRS_API is not enabled and this isn't production
      # allow the Fake API to be used when there are TRS response options
      # recorded for the TRN in the fake teacher store
      TRS::FakeTeacherStore.new.exists?(trn)
    end

    def real_client
      @real_client ||= TRS::HttpAPIClient.new
    end

    def fake_client
      @fake_client ||= TRS::FakeAPIClient.new
    end
  end
end
