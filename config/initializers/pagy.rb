require 'pagy/extras/array'
require 'pagy/extras/overflow'
require 'pagy/extras/size'

Pagy::DEFAULT[:overflow] = :empty_page # default  (other options: :last_page and :exception)
Pagy::DEFAULT[:size] = [1, 1, 1, 1].freeze
Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT.freeze
