namespace :extensions do
  desc "Generate EXTENSION-LEVEL events ;)"
  task backfill: :environment do
    logger = Logger.new($stdout)
    logger.info "Creating InductionExtension events..."

    InductionExtension.all.map do |extension|
      # Backfilled InductionExtensions do not have awareness of the AppropriateBody user
      author = Events::SystemAuthor.new

      if extension.teacher.induction_periods.empty?
        logger.info "InductionExtension '#{extension.id}' has no corresponding induction period"
        next
      end

      if extension.teacher.induction_periods.map(&:appropriate_body_id).uniq.count > 1
        # Harriet is a seed user with extensions and InductionPeriods with two different AppropriateBodies
        # We attribute the event to the last AppropriateBody
        # This will be visible to the AB user in their timeline
        logger.info "InductionExtension '#{extension.id}' may be attributed to the wrong appropriate body"
      end

      appropriate_body = extension.teacher.induction_periods.last.appropriate_body

      unless appropriate_body
        logger.info "InductionExtension '#{extension.id}' cannot be attributed to an appropriate body"
        next
      end

      if extension.created_at == extension.updated_at
        # create
        Events::Record.record_appropriate_body_adds_induction_extension_event(
          author:,
          appropriate_body:,
          teacher: extension.teacher,
          induction_extension: extension,
          modifications: [],
          happened_at: extension.created_at
        )

      else
        # update
        Events::Record.record_appropriate_body_updates_induction_extension_event(
          author:,
          appropriate_body:,
          teacher: extension.teacher,
          induction_extension: extension,
          modifications: [],
          happened_at: extension.updated_at
        )

      end
    end
  end
end
