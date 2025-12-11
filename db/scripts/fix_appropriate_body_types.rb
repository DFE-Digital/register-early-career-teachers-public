# Correct the body_type of LA records
#
# Local Authorities
AppropriateBody.where("body_type LIKE ?", "% LA").find_each do |ab|
  ab.update!(body_type: "local_authority")
end
