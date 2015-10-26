require 'rspec'
require 'rack/test'
require './lib/ramly/ramly'

module Helpers
  include Rack::Test::Methods

  def mock_app(base=Ramly::Base, &block)
    Ramly::Base.environment = :test
    @app = Ramly.new(base, &block)
  end

  def app
    Rack::Lint.new(@app)
  end
end

RSpec.configure do |c|
  c.include Helpers
end