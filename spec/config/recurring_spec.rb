RSpec.describe "recurring.yml" do
  it "references valid job classes in every entry" do
    YAML.load_file(Rails.root.join("config/recurring.yml")).each do |env, tasks|
      tasks.each do |key, task|
        klass_name = task["class"]
        next unless klass_name

        expect { klass_name.constantize }.not_to raise_error,
                                                 "Recurring task #{key.inspect} in #{env.inspect} references missing class #{klass_name}"
      end
    end
  end
end
