require "gias/api_client"
require "csv"

module GIAS
  class Importer
    ENCODING = "ISO-8859-1:UTF-8"
    SCHOOLS_FILENAME = "ecf_tech.csv"
    SCHOOL_LINKS_FILENAME = "links.csv"

    # file_source - :gias to fetch files from GIAS API
    #               :local to fetch supplemental files from filesystem (childrens centres)
    def initialize(file_source: :gias)
      @file_source = file_source
    end

    def fetch
      DeclarativeUpdates.skip(:metadata) do
        import_only? ? fetch_and_import_only : fetch_and_update
      end
      Metadata::Handlers::School.refresh_all_metadata!(async: true)
    end

    def foreach_school_row(&block)
      CSV.foreach(schools_file_path, headers: true, encoding: ENCODING, &block)
    end

    def foreach_school_link_row(&block)
      CSV.foreach(school_links_file_path, headers: true, encoding: ENCODING, &block)
    end

    def number_of_schools_to_import
      @number_of_schools_to_import ||= File.foreach(schools_file_path, encoding: ENCODING).count
    end

    def number_of_school_links_to_import
      @number_of_school_links_to_import ||= File.foreach(school_links_file_path, encoding: ENCODING).count
    end

    def parse_school_row(row)
      @school_row = GIAS::SchoolRow.new(row)
      if eligible_to_import?
        import_only? ? import_school! : update_school!
      end

      true
    end

    def parse_school_link_row(row)
      link_date = row.fetch("LinkEstablishedDate")
      link_type = row.fetch("LinkType")
      link_urn = row.fetch("LinkURN")
      urn = row.fetch("URN")
      gias_school = GIAS::School.find_by(urn:)

      if gias_school
        link = gias_school.gias_school_links
                          .create_with(link_date:, link_type:, link_urn:)
                          .find_or_create_by!(link_urn:)
        link.update!(link_type:) if link.link_type != link_type
      end

      true
    end

  private

    attr_reader :gias_school, :school_row, :file_source

    delegate :create_school!, :school, to: :gias_school
    delegate :attributes, :eligible_to_import?, :urn, to: :school_row

    # import only doesn't try to work out what has changed and does not include "closed" schools
    # we need to import schools first in an empty DB
    def fetch_and_import_only
      import_schools
      import_school_links
    end

    def fetch_and_update
      import_school_links
      import_schools
    end

    def gias_files
      @gias_files ||= GIAS::APIClient.new.get_files
    end

    def import_only?
      @import_only ||= GIAS::School.count.zero?
    end

    def import_school!
      @gias_school = GIAS::School.create_with(attributes).find_or_create_by!(urn:)
      school || create_school!
    end

    def import_schools
      foreach_school_row { |row| parse_school_row(row) }
    end

    def import_school_links
      foreach_school_link_row { |row| parse_school_link_row(row) }
    end

    def schools_file_path
      if file_source == :gias
        gias_files[SCHOOLS_FILENAME].path
      else
        Rails.application.config.gias_supplemental_schools_path
      end
    end

    def school_links_file_path
      if file_source == :gias
        gias_files[SCHOOL_LINKS_FILENAME].path
      else
        Rails.application.config.gias_supplemental_links_path
      end
    end

    def sync_changes!
      gias_school.assign_attributes(attributes)
      return unless gias_school.changed?

      GIAS::School.transaction do
        gias_school.save!
        # TODO: Handle gias_school.changes such as merges etc.
        #       Simple academisations type close/reopen will be just changing the :urn on the counterpart
        #       but links that are mergers and splits will need further thought
      end
    end

    def update_school!
      @gias_school = GIAS::School.find_by(urn:)
      gias_school ? sync_changes! : import_school!
    end
  end
end
