# Delete teacher records and all other associated records
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/remove_teacher_data.rb
# $ kubectl exec -it <pod-name> -- bundle exec rails runner db/scripts/remove_teacher_data.rb

teacher = Teacher.find(79_588)
RemoveTeacher.new(teacher.id).call
