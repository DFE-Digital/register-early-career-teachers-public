module AppropriateBodyHelper
  InductionProgrammeChoice = Struct.new(:identifier, :name)
  InductionOutcomeChoice = Struct.new(:identifier, :name)

  def induction_programme_choices
    [
      InductionProgrammeChoice.new(identifier: 'fip', name: 'Full induction programme'),
      InductionProgrammeChoice.new(identifier: 'cip', name: 'Core induction programme'),
      InductionProgrammeChoice.new(identifier: 'diy', name: 'School-based induction programme')
    ]
  end

  def induction_programme_choice_name(identifier)
    # FIXME: this is a temporary solution until we have real induction programme data
    induction_programme_choices.find { |choice| choice.identifier == identifier }&.name
  end

  def induction_outcome_choices
    [
      InductionProgrammeChoice.new(identifier: 'pass', name: 'Passed'),
      InductionProgrammeChoice.new(identifier: 'fail', name: 'Failed'),
    ]
  end

  def summary_card_for_teacher(teacher:)
    induction_start_date = Teachers::InductionPeriod.new(teacher).induction_start_date&.to_fs(:govuk)

    govuk_summary_card(title: Teachers::Name.new(teacher).full_name) do |card|
      card.with_action { govuk_link_to("Show", ab_teacher_path(teacher)) }
      card.with_summary_list(
        actions: false,
        rows: [
          { key: { text: "TRN" }, value: { text: teacher.trn } },
          {
            key: { text: "Induction start date" },
            value: { text: induction_start_date },
          },
          {
            key: { text: "Status" },
            value: {
              text: govuk_tag(
                **Teachers::InductionStatus.new(
                  teacher:,
                  induction_periods: teacher.induction_periods,
                  trs_induction_status: teacher.trs_induction_status
                ).status_tag_kwargs
              ),
            },
          },
        ]
      )
    end
  end

  def claimed_teachers_text(count)
    "#{number_with_delimiter(count)} claimed #{'induction'.pluralize(count)}"
  end

private

  def pending_induction_submission_full_name(pending_induction_submission)
    PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
  end
end
