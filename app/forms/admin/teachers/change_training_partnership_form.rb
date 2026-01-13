module Admin
  module Teachers
    class ChangeTrainingPartnershipForm
      include ActiveModel::Model

      attr_accessor :training_period, :school_partnership_id, :available_partnerships

      validates :school_partnership_id, presence: { message: "Select a partnership" }
      validate :school_partnership_available

      def school_partnership
        @school_partnership ||= available_partnerships.find { |sp| sp.id == school_partnership_id.to_i }
      end

      def save(author:)
        return false unless valid?

        TrainingPeriods::ChangePartnership.new(training_period:, school_partnership:, author:).call
        true
      rescue ActiveRecord::RecordInvalid => e
        errors.add(:base, e.record.errors.full_messages.to_sentence)
        false
      end

    private

      def school_partnership_available
        return if school_partnership.present?

        errors.add(:school_partnership_id, "Select a partnership that belongs to this school")
      end
    end
  end
end
