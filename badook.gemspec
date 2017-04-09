lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'capybara/badook/version'

Gem::Specification.new do |s|
  s.name          = 'badook'
  s.version       = Capybara::Badook::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Simon Vocella']
  s.email         = ['voxsim@gmail.com']
  s.homepage      = 'https://github.com/voxsim/badook'
  s.summary       = 'PhantomJS driver for Capybara'
  s.description   = 'Badook is a driver for Capybara that allows you to '\
                    'run your tests on a headless WebKit browser, provided by '\
                    'PhantomJS.'
  s.license       = 'MIT'
  s.require_paths = ['lib']
  s.files         = Dir.glob('{lib}/**/*') + %w(LICENSE README.md)

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'rest-client'

  s.add_runtime_dependency 'capybara',         '~> 2.1'
  s.add_runtime_dependency 'cliver',           '~> 0.3.1'

  s.add_development_dependency 'launchy',            '~> 2.0'
  s.add_development_dependency 'rspec',              '~> 3.5.0'
  s.add_development_dependency 'sinatra',            '~> 1.0'
  s.add_development_dependency 'rake'
  # s.add_development_dependency 'erubi'  # required by rbx
end
