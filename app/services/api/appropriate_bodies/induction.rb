module API
  module AppropriateBodies
    class Induction
      include ::AppropriateBodies::ClaimAnECT
      include Errors

      attr_reader :appropriate_body, :client

      # TODO: remove when AppropriateBodyPeriod to AppropriateBody rename is completed
      alias_method :appropriate_body_period, :appropriate_body

      def initialize(appropriate_body:, client:)
        @appropriate_body = appropriate_body
        @client = client
      end

      def claim!(trn:, date_of_birth: nil, started_on: nil, training_programme: nil)
        pending_induction_submission = appropriate_body.pending_induction_submissions.build(trn:, date_of_birth:)

        import_from_trs!(pending_induction_submission:)
        begin_claim!(pending_induction_submission:)
        register!(pending_induction_submission:, started_on:, training_programme:)

        as_claim(Teacher.find_by!(trn:).ongoing_induction_period)
      rescue StandardError => e
        rescue_with_handler(e) || raise
      # Purge the pending submission's TRS personal data on success or failure.
      # Not a transaction: it would hold a connection open while we call TRS.
      ensure
        pending_induction_submission.touch(:delete_at) if pending_induction_submission&.persisted?
      end

      # def release!; end

      # def pass!; end

    private

      # TODO: change to AppropriateBodyAPIAuthor
      def author = Events::OAuthClientAuthor.new(client:)

      def import_from_trs!(pending_induction_submission:)
        find_ect = FindECT.new(appropriate_body_period:, pending_induction_submission:)
        find_ect.import_from_trs! or raise Invalid, claim_errors(pending_induction_submission:)
      end

      def begin_claim!(pending_induction_submission:)
        check_ect = CheckECT.new(appropriate_body_period:, pending_induction_submission:)
        check_ect.begin_claim! or raise Invalid, claim_errors(pending_induction_submission:)
      end

      def register!(pending_induction_submission:, started_on:, training_programme:)
        register_ect = RegisterECT.new(appropriate_body_period:, pending_induction_submission:, author:)
        register_ect.register({ started_on:, training_programme: }) or raise Invalid, claim_errors(pending_induction_submission:)
      end

      def as_claim(induction_period) = induction_period.slice(:trn, :full_name, :started_on, :training_programme)
    end
  end
end
