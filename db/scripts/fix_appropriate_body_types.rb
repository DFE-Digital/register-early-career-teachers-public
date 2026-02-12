# Correct the body_type of LA records
#

AppropriateBodyPeriod.where("name LIKE ?", "% LA").find_each do |ab|
  ab.update!(body_type: "local_authority")
end

AppropriateBodyPeriod.where("name LIKE ?", "% Local Authority").find_each do |ab|
  ab.update!(body_type: "local_authority")
end
