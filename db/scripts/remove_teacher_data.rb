# Delete teacher records and all other associated records
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/remove_teacher_data.rb
# $ kubectl exec -it <pod-name> -- bundle exec rails runner db/scripts/remove_teacher_data.rb

[
  9000,
  38_625,
  16_390,
  29_640,
  26_939,
  56_966,
  66_740,
  25_882,
  61_669,
  34_433,
  34_472,
  76_279,
  76_278,
].map do |teacher_id|
  RemoveTeacher.new(teacher_id).call
end
