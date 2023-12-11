# frozen_string_literal: true

require './lib/fluent/plugin/dynatrace_constants'
require 'rake'

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-dynatrace'
  gem.version       = Fluent::Plugin::DynatraceOutputConstants.version
  gem.authors       = ['Dynatrace Open Source Engineering']
  gem.email         = ['opensource@dynatrace.com']
  gem.summary       = 'A fluentd output plugin for sending logs to the Dynatrace Generic log ingest API v2'
  gem.homepage      = 'https://github.com/dynatrace-oss/fluent-plugin-dynatrace'
  gem.licenses      = ['Apache-2.0']

  gem.metadata = {
    'bug_tracker_uri' => 'https://github.com/dynatrace-oss/fluent-plugin-dynatrace/issues',
    'documentation_uri' => 'https://github.com/dynatrace-oss/fluent-plugin-dynatrace',
    'source_code_uri' => 'https://github.com/dynatrace-oss/fluent-plugin-dynatrace'
  }

  gem.files         = FileList['lib/**/*.rb', 'LICENSE']

  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.7.0'

  gem.add_runtime_dependency 'fluentd', ['>= 0.14.22', '< 2']
  gem.add_development_dependency 'bundler', ['>= 2', '<3']
  gem.add_development_dependency 'rake', '>= 13.1.0', '< 13.2.0'
  gem.add_development_dependency 'rubocop', '1.59.0'
  gem.add_development_dependency 'rubocop-rake', '0.6.0'
  gem.add_development_dependency 'test-unit', '>= 3.6', '< 3.7.0'
end
