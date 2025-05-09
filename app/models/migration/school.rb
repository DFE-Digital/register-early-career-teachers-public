module Migration
  class School < Migration::Base
    has_many :school_cohorts
    has_many :partnerships

    def in_england?
      english_district_code?(administrative_district_code)
    end

    def english_district_code?(district_code)
      # expanded to include the 9999 code which seems to have crept in and is preventing a couple of schools onboarding
      # the establishment codes should filter out any that should not come in that are 9999 district
      district_code.to_s.match?(/^([Ee]|9999)/)
    end
  end
end
