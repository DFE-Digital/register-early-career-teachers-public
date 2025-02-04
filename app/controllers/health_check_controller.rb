class HealthCheckController < ApplicationController
  skip_before_action :authenticate

  def show = render(json:)

private

  def json
    { commit_sha:, database: }.to_json
  end

  def commit_sha
    ENV.fetch('COMMIT_SHA', 'UNKNOWN')
  end

  def database
    'connected' if ActiveRecord::Base.connection.execute('select 1 as ok').tuple(0)['ok'] == 1
  rescue PG::ConnectionBad
    'not connected'
  end
end
