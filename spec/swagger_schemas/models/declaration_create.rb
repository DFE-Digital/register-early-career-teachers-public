require_relative "declaration"

DECLARATION_CREATE = DECLARATION.deep_dup.tap { |schema|
  schema[:properties][:attributes][:properties][:evidence_held][:description] = "The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period. For retained-2 declarations, providers will need to confirm if the engagement threshold has been reached and only accept either the ‘75-percent-engagement-met’ or ‘75-percent-engagement-met-reduced-induction’ values."
}.freeze
