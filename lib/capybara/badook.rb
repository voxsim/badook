if RUBY_VERSION < '1.9.2'
  raise 'This version of Capybara/Badook does not support Ruby versions ' \
        'less than 1.9.2.'
end

require 'capybara'

module Capybara
  module Badook
    require 'capybara/badook/utility'
    require 'capybara/badook/driver'
    require 'capybara/badook/node'
    require 'capybara/badook/phantomjs'
    require 'capybara/badook/inspector'
  end
end

Capybara.register_driver :badook do |app|
  Capybara::Badook::Driver.new(app)
end
