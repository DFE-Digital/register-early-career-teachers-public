class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

private

  def author
    Current.user || Events::SystemAuthor.new
  end
end
