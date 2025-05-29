require 'pagy/extras/countless'
require 'pagy/extras/array'
require 'pagy/extras/overflow'
require 'pagy/extras/size'

Pagy::DEFAULT[:overflow] = :empty_page # default  (other options: :last_page and :exception)
Pagy::DEFAULT[:size] = [1, 1, 1, 1].freeze # nav bar links
Pagy::DEFAULT[:limit] = 20 # items per page
Pagy::DEFAULT[:api_per_page] = 100 # items per page (API)
Pagy::DEFAULT[:api_max_per_page] = 3_000 # max items per page (API)
Pagy::DEFAULT.freeze
