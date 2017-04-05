POLTERGEIST_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(POLTERGEIST_ROOT + '/lib')

require 'bundler/setup'

require 'rspec'
require 'capybara/spec/spec_helper'
require 'capybara/badook'

require 'support/test_app'
require 'support/spec_logger'

Capybara.register_driver :badook do |app|
  debug = !ENV['DEBUG'].nil?
  options = {
    logger: TestSessions.logger,
    inspector: debug,
    debug: debug
  }

  options[:phantomjs] = ENV['PHANTOMJS'] if ENV['TRAVIS'] && ENV['PHANTOMJS']

  Capybara::Poltergeist::Driver.new(
    app, options
  )
end
