module ProgrammeHelper
  def training_programme_name(training_programme)
    ::TRAINING_PROGRAMME.fetch(training_programme&.to_sym, 'Programme type is not recognised')
  end

  def previous_choice_message(use_previous_ect_choices)
    return "Yes, use the programme choices used by my school previously" if use_previous_ect_choices

    "No, don't use the programme choices used by my school previously"
  end
end
