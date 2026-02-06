# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "API" # Application Programming Interface
  inflect.acronym "DfE" # Department for Education
  inflect.acronym "ECF" # Early Career Framework
  inflect.acronym "ECF1" # Early Career Framework 1 (the old service, Manage ECTs)
  inflect.acronym "ECF2" # Early Career Framework 2 (the new service, Register ECTs)
  inflect.acronym "ECT" # Early Career Teacher
  inflect.acronym "ECTs" # Early Career Teachers
  inflect.acronym "GIAS" # Get Information About Schools
  inflect.acronym "ITT" # Initial teacher training
  inflect.acronym "OmniAuth"
  inflect.acronym "OpenID"
  inflect.acronym "OTP" # One-time Password
  inflect.acronym "RIAB" # Record Inductions as an Appropriate Body
  inflect.acronym "TRN" # Teacher Reference Number
  inflect.acronym "TRS" # Teaching Record System
  inflect.acronym "URN" # Unique Reference Number
  inflect.acronym "VAT" # Value Added Tax

  inflect.irregular "was", "were"
end
