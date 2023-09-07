$:.push File.expand_path('../lib', __FILE__)

require 'dradis/plugins/projects/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.platform = Gem::Platform::RUBY
  spec.name = 'dradis-projects'
  spec.version = Dradis::Plugins::Projects::VERSION::STRING
  spec.summary = 'Project export/upload for the Dradis Framework.'
  spec.description = 'This plugin allows you to dump the contents of the repo into a zip archive and restore the state from one of them.'

  spec.license = 'GPL-2'

  spec.authors = ['Daniel Martin']
  spec.homepage = 'http://dradis.com'

  spec.files = `git ls-files`.split($\)
  spec.executables = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'dradis-plugins', '>= 4.8.0'
  spec.add_dependency 'rubyzip'
end
