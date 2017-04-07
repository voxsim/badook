BADOOK_ROOT = File.expand_path('../..', __FILE__)
$:.unshift(BADOOK_ROOT + '/lib')

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

  Capybara::Badook::Driver.new(
    app, options
  )
end

module TestSessions
  def self.logger
    @logger ||= SpecLogger.new
  end

  Badook = Capybara::Session.new(:badook, TestApp)
end

module Badook
  module SpecHelper
    class << self
      def set_capybara_wait_time(t)
        Capybara.default_max_wait_time = t
      rescue
        Capybara.default_wait_time = t
      end
    end
  end
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false if ENV['TRAVIS']

RSpec.configure do |config|
  config.before do
    TestSessions.logger.reset
  end

  config.after do |example|
    if ENV['DEBUG']
      puts TestSessions.logger.messages
    elsif ENV['TRAVIS'] && example.exception
      example.exception.message << "\n\nDebug info:\n" + TestSessions.logger.messages.join("\n")
    end
  end

  Capybara::SpecHelper.configure(config)

  config.filter_run_excluding :full_description => lambda { |description, metadata|
    #test is marked pending in Capybara but Badook passes - disable here - have our own test in driver spec
    description =~ /Capybara::Session Badook node #set should allow me to change the contents of a contenteditable elements child/
  }

  config.before(:each) do
    Badook::SpecHelper.set_capybara_wait_time(0)
  end

  [:js, :modals, :windows].each do |cond|
    config.before(:each, :requires => cond) do
      Badook::SpecHelper.set_capybara_wait_time(1)
    end
  end
end

def phantom_version_is?(ver_spec, driver)
  Cliver.detect(driver.options[:phantomjs] || Capybara::Badook::Client::PHANTOMJS_NAME, ver_spec)
end

