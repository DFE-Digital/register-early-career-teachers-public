namespace :gias do
  desc "Import schools data from Get Information About Schools"
  task import: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing GIAS schools data, this may take a couple minutes..."
    GIAS::Importer.new.fetch
    logger.info "GIAS schools data import complete!"
  end

  desc "Import children centres schools data from CSV"
  task import_childrens_centres: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing Childrens Centres GIAS schools data, this may take a couple minutes..."
    GIAS::Importer.new(file_source: :local).fetch
    logger.info "Childrens Centres schools data import complete!"
  end
end
