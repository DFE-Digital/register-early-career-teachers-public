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
      @urns_for_reconciliation = []
    end

    def fetch
      first_import? ? fetch_and_import_only : fetch_and_update

      urns_for_reconciliation.compact.uniq
    end

  private

    attr_reader :gias_school, :school_row, :file_source
    attr_accessor :urns_for_reconciliation

    delegate :attributes, :eligible_to_import?, :urn, to: :school_row

    # We need to import schools first in an empty DB.  This will skip schools closed before 2020
    # It's more efficient to skip metadata during import and refresh it all in background jobs
    # at the end when creating a lot of schools.

    def fetch_and_import_only
      DeclarativeUpdates.skip(:metadata) do
        import_schools
        import_school_links
      end

      Metadata::Handlers::School.refresh_all_metadata!(async: true)
    end

    def fetch_and_update
      import_schools
      import_school_links
    end

    def first_import?
      @first_import ||= GIAS::School.count.zero?
    end

    def import_schools
      foreach_school_row { |row| parse_school_row(row) }
    end

    def import_school_links
      foreach_school_link_row { |row| parse_school_link_row(row) }
    end

    def foreach_school_row(&block)
      CSV.foreach(schools_file_path, headers: true, encoding: ENCODING, &block)
    end

    def foreach_school_link_row(&block)
      CSV.foreach(school_links_file_path, headers: true, encoding: ENCODING, &block)
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
        urns_for_reconciliation << link.urn if needs_reconciliation?(link, link_type)

        link.update!(link_type:) if link.link_type != link_type
      end

      true
    end

    def needs_reconciliation?(link, imported_link_type)
      link.link_type != imported_link_type || link.previously_new_record? || link.link_date == Date.current
    end

    def parse_school_row(row)
      @school_row = GIAS::SchoolRow.new(row)

      if eligible_to_import?
        first_import? ? import_school! : update_school!
      end

      true
    end

    def import_school!
      @gias_school = GIAS::School.create_with(attributes).find_or_create_by!(urn:)
      urns_for_reconciliation << urn if @gias_school.previously_new_record?
    end

    def update_school!
      @gias_school = GIAS::School.find_by(urn:)
      gias_school ? sync_changes! : import_school!
    end

    def sync_changes!
      gias_school.assign_attributes(attributes)

      # Ensure that we trigger reconciliation on the day a school closes
      # in case it was scheduled to close in the future
      urns_for_reconciliation << gias_school.urn if gias_school.closed_on == Date.current

      return unless gias_school.changed?

      modifications = gias_school.changes
      eligible_change = modifications["eligible"]

      urns_for_reconciliation << gias_school.urn if status_changed_to_open_or_closed?(gias_school)

      GIAS::School.transaction do
        gias_school.save!
        record_eligibility_change_event!(modifications) if eligible_change
      end
    end

    def status_changed_to_open_or_closed?(gias_school)
      return false unless gias_school.status_changed?

      gias_school.open_status? || gias_school.closed_status?
    end

    def record_eligibility_change_event!(modifications)
      eligibility = modifications.fetch("eligible").last
      school = gias_school.school
      school_name = school&.name || gias_school.name

      Events::Record.record_school_eligibility_changed_event!(
        author: Events::SystemAuthor.new,
        school:,
        school_name:,
        eligibility:,
        modifications:
      )
    end

    def gias_files
      @gias_files ||= GIAS::APIClient.new.get_files
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
  end
end
