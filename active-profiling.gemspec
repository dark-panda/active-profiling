# -*- encoding: utf-8 -*-

require File.expand_path('../lib/active-profiling/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "active-profiling"
  s.version = ActiveProfiling::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "A Rails profiling suite."
  s.summary = s.description
  s.email = "dark.panda@gmail.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/dark-panda/active-profiling"
  s.require_paths = ["lib"]

  s.add_dependency("rails", [">= 3.0"])
  s.add_dependency("rdoc")
  s.add_dependency("rake", ["~> 0.9"])
end

