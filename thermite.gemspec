require 'English'

Gem::Specification.new do |s|
  s.name        = 'thermite'
  s.version     = '0.13.0'
  s.summary     = 'Rake helpers for Rust+Ruby'
  s.description = 'A Rake-based helper for building and distributing Rust-based Ruby extensions'

  s.authors     = ['Mark Lee']
  s.email       = 'malept@users.noreply.github.com'
  s.homepage    = 'https://github.com/malept/thermite'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.require_paths = %w[lib]

  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency 'minitar', '~> 0.6'
  s.add_runtime_dependency 'rake', '>= 10'
  s.add_runtime_dependency 'tomlrb', '~> 1.2'
  s.add_development_dependency 'minitest', '~> 5.9'
  s.add_development_dependency 'mocha', '~> 1.1'
  s.add_development_dependency 'rubocop', '~> 0.49'
  s.add_development_dependency 'yard', '~> 0.9'
end
