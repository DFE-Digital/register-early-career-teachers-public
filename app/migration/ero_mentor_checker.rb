class EROMentorChecker
  attr_reader :participant_profile

  def initialize(participant_profile:)
    @participant_profile = participant_profile
  end

  def ero_mentor?
    participant_profile.mentor? && Migration::ECFIneligibleParticipant.exists?(trn:)
  end

  def relevant_declarations
    @relevant_declarations ||= participant_profile.participant_declarations.where(state: %w[paid clawed_back])
  end

  def ero_mentor_with_declarations?
    ero_mentor? && relevant_declarations.any?
  end

  def ero_mentor_without_declarations?
    ero_mentor? && relevant_declarations.none?
  end

private

  def trn
    participant_profile.teacher_profile.trn
  end
end
