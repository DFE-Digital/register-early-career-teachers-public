namespace :gias do
  desc "Import schools data from Get Information About Schools without reconciliation"
  task import: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing GIAS schools data without reconciliation, this may take several minutes..."
    GIAS::Importer.new.fetch
    logger.info "GIAS schools data import complete!"
  end

  desc "Import schools data from Get Information About Schools and reconcile with existing records"
  task import_and_reconcile: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing GIAS schools data and reconciling with School records, this may take several minutes..."
    urns = GIAS::Importer.new.fetch
    logger.info "GIAS schools data import complete, #{urns.count} schools to reconcile"

    unreconcilable_urns = GIAS::Reconcile.new(urns).call

    if unreconcilable_urns.any?
      logger.warn "The following URNs could not be reconciled: #{unreconcilable_urns.join(', ')}"
    else
      logger.info "All URNs reconciled successfully!"
    end

    logger.info "GIAS schools data import and reconciliation complete!"
  end

  desc "Reconcile GIAS schools data for URNs"
  task :reconcile, [:urns] => :environment do |_task, args|
    logger = Logger.new($stdout)

    if args[:urns].blank?
      logger.warn "No URNs provided. Usage: rake gias:reconcile[12345,67890]"
      next
    end

    urns = args.fetch(:urns)
      .split(",")
      .map(&:strip)
      .map(&:to_i)

    logger.info "Reconciling GIAS schools data for #{urns.count} URNs"

    unreconcilable_urns = GIAS::Reconcile.new(urns).call

    if unreconcilable_urns.any?
      logger.warn "The following URNs could not be reconciled: #{unreconcilable_urns.join(', ')}"
    else
      logger.info "All URNs reconciled successfully!"
    end

    logger.info "GIAS schools data reconciliation complete!"
  end

  desc "Import children centres schools data from CSV"
  task import_childrens_centres: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing Childrens Centres GIAS schools data, this may take several minutes..."
    urns = GIAS::Importer.new(file_source: :local).fetch
    logger.info "GIAS schools data import complete, #{urns.count} schools to reconcile"
    unreconcilable_urns = GIAS::Reconcile.new(urns).call

    if unreconcilable_urns.any?
      logger.warn "The following URNs could not be reconciled: #{unreconcilable_urns.join(', ')}"
    else
      logger.info "All URNs reconciled successfully!"
    end
    logger.info "Childrens Centres schools data import and reconciliation complete!"
  end
end
