# Transfer all inductions on or after a specific date to another appropriate body
# 1. transfer induction ownership
# 2. amend induction event history
# 3. output useful summary of alterations
#
module RIAB
  class FullTransferInductionPeriods < TransferInductionPeriods
    def call(rollback: false)
      configure_table_print(:csv)

      events = events_for(inductions)

      Rails.logger.debug "-------------------"
      Rails.logger.debug "Will transfer #{inductions.count} induction periods"
      Rails.logger.debug "Will transfer #{events.count} events"

      total_count
      export_summary_for(events)

      InductionPeriod.transaction do
        Rails.logger.debug "-------------------"
        Rails.logger.debug "Starting transfer..."

        inductions.each do |induction_period|
          transfer_induction_period(induction_period)
          induction_period.events.each { |event| transfer_event(event) }
        end

        export_summary_for(events_for(inductions))
        total_count

        if rollback
          Rails.logger.debug "Rolling back..."
          raise ActiveRecord::Rollback
        end
      end
    end

  private

    # @return [InductionPeriod::ActiveRecord_Relation] inductions that came after cut off date
    def target_inductions
      InductionPeriod
        .for_appropriate_body(current_appropriate_body)
        .started_on_or_after(cut_off_date)
        .order(started_on: :asc)
    end

    # @param event [Event]
    # @return [Boolean]
    def transfer_event(event)
      event.update!(
        appropriate_body: new_appropriate_body,
        heading: event.heading.gsub(current_appropriate_body.name, new_appropriate_body.name),
        body: "Event transferred from #{current_appropriate_body.name} to #{new_appropriate_body.name} on #{Date.current}"
      )
    end

    # @param induction_period [InductionPeriod]
    # @return [Boolean]
    def transfer_induction_period(induction_period)
      induction_period.update!(
        appropriate_body: new_appropriate_body
      )
    end
  end
end
