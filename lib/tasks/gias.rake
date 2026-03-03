namespace :gias do
  desc "Import schools data from Get Information About Schools and create missing School records"
  task import_with_school_creation: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing GIAS schools data, this may take several minutes..."
    GIAS::Importer.new(auto_create_school: true).fetch
    logger.info "GIAS schools data import complete!"
  end

  desc "Import schools data from Get Information About Schools without creating missing School records"
  task import_without_school_creation: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing GIAS schools data without school creation, this may take several minutes..."
    GIAS::Importer.new(auto_create_school: false).fetch
    logger.info "GIAS schools data import complete!"
  end

  desc "Import children centres schools data from CSV"
  task import_childrens_centres: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing Childrens Centres GIAS schools data, this may take several minutes..."
    GIAS::Importer.new(file_source: :local, auto_create_school: true).fetch
    logger.info "Childrens Centres schools data import complete!"
  end
end
