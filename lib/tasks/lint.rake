desc "Lint code repository"
namespace :lint do
  desc "Lint JavaScript code"
  task js: :environment do
    system "npm run lint:js"
  end
  desc "Lint SCSS code"
  task scss: :environment do
    system "npm run lint:scss"
  end
end
