class PersonasController < ApplicationController
  layout "full"

  def index
    @personas = Sessions::PersonaLoader.new("config/personas.yml").personas
  end
end
