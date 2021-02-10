# frozen_string_literal: true

require './lib/fluent/plugin/dynatrace_constants'

Gem::Specification.new 'fluent-plugin-dynatrace', Fluent::Plugin::DynatraceOutputConstants.version do |gem|
  gem.authors       = ['Dynatrace Open Source']
  gem.email         = ['opensource@dynatrace.com']
  gem.summary       = 'A generic Fluentd output plugin to send logs to Dynatrace'
  gem.homepage      = 'https://github.com/Dynatrace-OSS/fluent-plugin-dynatrace'
  gem.licenses      = ['Apache-2.0']

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.4.0'

  gem.add_runtime_dependency 'fluentd', ['>= 0.14.22', '< 2']
  gem.add_development_dependency 'bundler', ['>= 2', '<3']
  gem.add_development_dependency 'rake', '13.0.3'
  gem.add_development_dependency 'rubocop', '1.9.1'
  gem.add_development_dependency 'rubocop-rake', '0.5.1'
end
