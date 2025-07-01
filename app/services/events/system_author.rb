class Events::SystemAuthor
  def system_author_params
    { author_type: 'system' }
  end

  # @return [Hash{Symbol => Object}]
  def relationship_attributes
    {}
  end
end
