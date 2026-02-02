require "gias/api_client"
require "csv"

module GIAS
  class SchoolRow
    attr_reader :data

    RECENT_CLOSURE_CUTOFF_DATE = Date.new(2020, 1, 1)

    def initialize(data)
      @data = data
    end

    def attributes
      {
        address_line1:,
        address_line2:,
        address_line3:,
        administrative_district_name:,
        closed_on:,
        eligible:,
        establishment_number:,
        in_england:,
        local_authority_code:,
        name:,
        opened_on:,
        phase_name:,
        postcode:,
        primary_contact_email:,
        secondary_contact_email:,
        section_41_approved:,
        status:,
        type_name:,
        ukprn:,
        urn:,
        website:,
      }
    end

    def address_line1
      @address_line1 ||= data.fetch("Street")
    end

    def address_line2
      @address_line2 ||= data.fetch("Locality").presence
    end

    def address_line3
      @address_line3 ||= data.fetch("Town").presence
    end

    def administrative_district_name
      # not in export for Childrens Centres
      @administrative_district_name ||= data.fetch("DistrictAdministrative (name)", nil)
    end

    def closed_on
      # not in export for Childrens Centres
      @closed_on ||= data.fetch("CloseDate", nil)
    end

    def eligible_to_import?
      open_or_recently_closed? && in_england? && (eligible_type? || independent_school_type?)
    end

    def eligible
      @eligible ||= open? && in_england? && (eligible_type? || (independent_school_type? && section_41_approved?))
    end

    alias_method :eligible?, :eligible

    def eligible_type?
      @eligible_type ||= GIAS::Types::ELIGIBLE_TYPES.include?(type_name)
    end

    def establishment_number
      # not in export for Childrens Centres
      @establishment_number ||= data.fetch("EstablishmentNumber", nil).presence
    end

    def independent_school_type?
      @independent_school_type ||= GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(type_name)
    end

    def in_england
      @in_england ||= GIAS::Types::IN_ENGLAND_TYPES.include?(type_name)
    end

    alias_method :in_england?, :in_england

    def local_authority_code
      @local_authority_code ||= data.fetch("LA (code)").to_i
    end

    def name
      @name ||= data.fetch("EstablishmentName")
    end

    def opened_on
      @opened_on ||= data.fetch("OpenDate")
    end

    def open?
      @open ||= status.in?(%w[open proposed_to_close])
    end

    def open_or_recently_closed?
      open? || (closed_on.present? && Date.parse(closed_on) >= RECENT_CLOSURE_CUTOFF_DATE)
    end

    def phase_name
      # Children's centre export doesn't have this column but it used to be "Not applicable" in the old combined export
      @phase_name ||= data.fetch("PhaseOfEducation (name)", "Not applicable")
    end

    def postcode
      @postcode ||= data.fetch("Postcode")
    end

    def primary_contact_email
      # not in export for Childrens Centres
      @primary_contact_email ||= data.fetch("MainEmail", nil).presence
    end

    def secondary_contact_email
      # not in export for Childrens Centres
      @secondary_contact_email ||= data.fetch("AlternativeEmail", nil).presence
    end

    def section_41_approved
      # not in export for Childrens Centres
      @section_41_approved ||= data.fetch("Section41Approved (name)", nil) == "Approved"
    end

    alias_method :section_41_approved?, :section_41_approved

    def status
      @status ||= data.fetch("EstablishmentStatus (name)").underscore.parameterize(separator: "_").sub("open_but_", "")
    end

    def type_code
      @type_code ||= data.fetch("TypeOfEstablishment (code)")
    end

    def type_name
      @type_name ||= data.fetch("TypeOfEstablishment (name)")
    end

    def ukprn
      # not in export for Childrens Centres
      @ukprn ||= data.fetch("UKPRN", nil).presence
    end

    def urn
      @urn ||= data.fetch("URN").to_i
    end

    def website
      @website ||= data.fetch("SchoolWebsite").presence
    end
  end
end
