# frozen_string_literal: true

require File.expand_path('lib/active-profiling/version', __dir__)

Gem::Specification.new do |s|
  s.name = 'active-profiling'
  s.version = ActiveProfiling::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 3.0'

  s.authors = ['J Smith']
  s.description = 'A Rails profiling suite.'
  s.summary = s.description
  s.email = 'dark.panda@gmail.com'
  s.license = 'MIT'
  s.extra_rdoc_files = [
    'README.rdoc'
  ]
  s.files = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.homepage = 'https://github.com/dark-panda/active-profiling'
  s.require_paths = ['lib']

  s.add_dependency('rails', ['>= 6.0'])
  s.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
