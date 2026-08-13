class HealthCheckController < ApplicationController
  def show = render(json:)

private

  def json
    { commit_sha:, postgresql:, redis: }.to_json
  end

  def commit_sha
    ENV.fetch("COMMIT_SHA", "UNKNOWN")
  end

  def postgresql
    "connected" if ActiveRecord::Base.connection.execute("select 1 as ok").tuple(0)["ok"] == 1
  rescue PG::ConnectionBad
    "not connected"
  end

  def redis
    "connected" if Rails.cache.redis.with(&:ping) == "PONG"
  rescue RedisClient::CannotConnectError
    "cannot connect"
  rescue RedisClient::Error
    "error connecting"
  end
end
