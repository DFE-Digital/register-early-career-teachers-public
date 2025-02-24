module Migration
  class InductionRecordComponent < ViewComponent::Base
    attr_reader :induction_record

    def initialize(induction_record:)
      @induction_record = induction_record
    end

    def migrated_mentor
      return unless mentor_present?

      Teacher.find_by(ecf_mentor_profile_id: induction_record.mentor_profile_id)
    end

    def mentor_present?
      induction_record.mentor_profile_id.present?
    end

    def attributes_for(_attr)
      {}
    end
  end
end
