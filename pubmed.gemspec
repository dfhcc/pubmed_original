# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pubmed/version'

Gem::Specification.new do |spec|
  spec.name          = 'pubmed'
  spec.version       = Pubmed::VERSION
  spec.authors       = ['Tom Leonard', 'Chris Pallotta', 'Scott Pullen', 'Keith Morrison']
  spec.email         = ['Thomas_Leonard@dfci.harvard.edu', 'ChristopherF_Pallotta@dfci.harvard.edu', 'ScottTPullen@dfci.harvard.edu']
  spec.description   = %q{NCBI PUBMED API}
  spec.summary       = %q{NCBI PUBMED API}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 2.13'
  spec.add_development_dependency 'debugger'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'nokogiri', '~> 1.5'
end
