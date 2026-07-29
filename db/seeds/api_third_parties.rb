# Organisations external to DfE which Appropriate bodies use to manage induction periods
[
  { name: "ECT Manager", email: "ectm@nager" },
  { name: "Mozaic", email: "moz@ic" }
].each do |provider|
  API::ThirdParty.create(name: provider[:name], email: provider[:email])
end
