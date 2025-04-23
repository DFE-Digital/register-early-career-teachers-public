module AppropriateBodyHelper
  FormChoice = Data.define(:identifier, :name)

  def appropriate_bodies_options_for_collection
    AppropriateBody.teaching_school_hub.select(:id, :name).all
  end

  def induction_programme_choices
    ::INDUCTION_PROGRAMMES.map { |key, value| FormChoice.new(key.to_s, value) }
  end

  # TODO: not currently in use?
  def induction_outcome_choices
    ::INDUCTION_OUTCOMES.map { |key, value| FormChoice.new(key.to_s, value) }
  end

  def summary_card_for_teacher(teacher:)
    govuk_summary_card(title: Teachers::Name.new(teacher).full_name) do |card|
      card.with_action { govuk_link_to("Show", ab_teacher_path(teacher)) }
      card.with_summary_list(
        actions: false,
        rows: [
          { key: { text: "TRN" }, value: { text: teacher.trn } },
          {
            key: { text: "Induction start date" },
            value: { text: Teachers::InductionPeriod.new(teacher).formatted_induction_start_date },
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

  def claimed_inductions_text(count)
    "#{number_with_delimiter(count)} claimed #{'induction'.pluralize(count)}"
  end

  def trs_alerts_text(alerts_present)
    if alerts_present
      link = govuk_link_to("Check a teacher's record service", 'https://www.gov.uk/guidance/check-a-teachers-record')

      safe_join(["Yes", %(Use the #{link} to get more information.).html_safe], tag.br)
    else
      "No"
    end
  end

  def induction_extensions(teacher)
    return if teacher.blank?

    @induction_extensions ||= Teachers::InductionExtensions.new(teacher)
  end

  def show_extensions_row?(teacher)
    induction_extensions(teacher)&.extended?
  end

private

  def pending_induction_submission_full_name(pending_induction_submission)
    PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
  end
end
