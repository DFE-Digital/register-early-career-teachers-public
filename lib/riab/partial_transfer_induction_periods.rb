# Stop inductions on a specific date and resume them with another appropriate body
# 1. curtail induction with old AB at cut off
# 2. resume induction with new AB
# 3. amend induction event history
# 4. generate missing events for the transfer
# 5. output useful summary of alterations
#
module RIAB
  class PartialTransferInductionPeriods < TransferInductionPeriods
    def call(rollback: false)
      configure_table_print(:csv)

      trns = target_inductions.joins(:teacher).pluck(:trn)
      events = events_for(inductions)

      Rails.logger.debug "-------------------"
      Rails.logger.debug "Will curtail #{inductions.count} induction periods for current AB"
      Rails.logger.debug "Will create #{inductions.count} induction periods for new AB"
      Rails.logger.debug "Will create #{inductions.count} release events for current AB"
      Rails.logger.debug "Will create #{inductions.count} claim events for new AB"
      Rails.logger.debug "Will transfer #{events.where.not(event_type: :induction_period_opened).count} events for closed inductions to the new AB"

      total_count
      export_summary_for(inductions.order(:teacher_id), headers: INDUCTION_TABLE_HEADERS)

      InductionPeriod.transaction do
        Rails.logger.debug "-------------------"
        Rails.logger.debug "Starting transfer..."

        inductions.each do |induction_period|
          original_induction_values = induction_period.slice(:finished_on, :induction_programme, :training_programme, :number_of_terms, :outcome)
          induction_period.update!(finished_on: 1.day.before(cut_off_date))

          new_induction_period = InductionPeriod.create!(
            appropriate_body: new_appropriate_body,
            started_on: cut_off_date,
            teacher: induction_period.teacher,
            **original_induction_values
          )

          create_release_event(induction_period:)
          create_claim_event(induction_period: new_induction_period)

          induction_period.events.happened_on_or_after(cut_off_date).each do |event|
            event.update!(
              appropriate_body: new_appropriate_body,
              induction_period: new_induction_period,
              heading: event.heading.gsub(current_appropriate_body.name, new_appropriate_body.name),
              body: "Event transferred from #{current_appropriate_body.name} to #{new_appropriate_body.name} on #{Date.current}"
            )
          end
        end

        new_inductions = processed_inductions(trns:)
        edited = new_inductions.where(finished_on: 1.day.before(cut_off_date))
        migrated = new_inductions.where(started_on: cut_off_date)

        export_summary_for(edited, headers: INDUCTION_TABLE_HEADERS)
        export_summary_for(migrated, headers: INDUCTION_TABLE_HEADERS)
        total_count

        if rollback
          Rails.logger.debug "Rolling back..."
          raise ActiveRecord::Rollback
        end
      end
    end

  private

    # @return [InductionPeriod::ActiveRecord_Relation] inductions that span cut off date
    def target_inductions
      InductionPeriod
        .for_appropriate_body(current_appropriate_body)
        .started_before(cut_off_date)
        .finished_on_or_after(cut_off_date)
    end

    # @param trns [Array<String>]
    # @return [InductionPeriod::ActiveRecord_Relation]
    def processed_inductions(trns:)
      InductionPeriod
        .joins(:teacher)
        .where(teacher: { trn: trns }, appropriate_body: [current_appropriate_body, new_appropriate_body])
        .order(:appropriate_body_id, :teacher_id)
    end

    # @param induction_period [InductionPeriod]
    # @return [Boolean]
    def create_release_event(induction_period:)
      Event.create!(
        appropriate_body: current_appropriate_body,
        induction_period:,
        teacher: induction_period.teacher,
        happened_at: induction_period.finished_on,
        heading: "#{teacher_full_name(induction_period.teacher)} was released by #{current_appropriate_body.name}",
        event_type: "induction_period_closed",
        author_type: "system",
        body: "Induction period curtailed because it finished after appropriate body status lost"
      )
    end

    # @param induction_period [InductionPeriod]
    # @return [Boolean]
    def create_claim_event(induction_period:)
      Event.create!(
        appropriate_body: new_appropriate_body,
        induction_period:,
        teacher: induction_period.teacher,
        happened_at: induction_period.started_on,
        heading: "#{teacher_full_name(induction_period.teacher)} was claimed by #{new_appropriate_body.name}",
        event_type: "induction_period_opened",
        author_type: "system",
        body: "Induction period started when transferred from #{current_appropriate_body.name}"
      )
    end

    # @param teacher [Teacher]
    # @return [String]
    def teacher_full_name(teacher)
      ::Teachers::Name.new(teacher).full_name
    end
  end
end
