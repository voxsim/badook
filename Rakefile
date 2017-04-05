require 'bundler/setup'
require 'rspec/core/rake_task'

require 'capybara/badook/version'

RSpec::Core::RakeTask.new('test')
task default: [:test]

task :release do
  version = Capybara::Badook::VERSION
  puts "Releasing #{version}, y/n?"
  exit(1) unless STDIN.gets.chomp == 'y'
  sh 'gem build badook.gemspec && ' \
     "gem push badook-#{version}.gem && " \
     "git tag v#{version} && " \
     'git push --tags'
end
