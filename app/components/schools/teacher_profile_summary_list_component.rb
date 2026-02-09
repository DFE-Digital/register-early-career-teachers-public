module Schools
  class TeacherProfileSummaryListComponent < ApplicationComponent
    include TeacherHelper
    include ECTHelper

    def initialize(ect, current_school: nil)
      @ect = ect
      @current_school = current_school
    end

  private

    def show_withdrawn_or_deferred_status?
      return false if leaving_school?
      return false if exempt?

      withdrawn? || deferred?
    end

    def withdrawn_or_deferred_tag
      return unless withdrawn? || deferred?

      if withdrawn?
        govuk_tag(text: "Action required", colour: "red")
      else
        govuk_tag(text: "Training paused", colour: "orange")
      end
    end

    def withdrawn_or_deferred_message_text
      return unless withdrawn? || deferred?

      subject, verb = lead_provider_subject_and_verb
      name = teacher_full_name(@ect.teacher)

      if withdrawn?
        "#{subject} #{verb} told us that #{name} is no longer training with them. Contact them if you think this is an error."
      else
        "#{subject} #{verb} told us that #{name}'s training is paused. Contact them if you think this is an error."
      end
    end

    def lead_provider_subject_and_verb
      lead_provider_name = @ect.latest_started_lead_provider_name
      subject = lead_provider_name.presence || "The lead provider"
      verb = lead_provider_name.present? ? "have" : "has"
      [subject, verb]
    end

    def training_status
      @training_status ||= @ect.latest_started_training_status
    end

    def withdrawn?
      training_status == :withdrawn
    end

    def deferred?
      training_status == :deferred
    end

    def leaving_school?
      @current_school && @ect.leaving_reported_for_school?(@current_school)
    end

    def exempt?
      @ect.teacher.trs_induction_status == "Exempt"
    end

    def current_mentor = mentorship.current_mentor

    def mentorship = @mentorship ||= ECTAtSchoolPeriods::Mentorship.new(@ect)
  end
end
