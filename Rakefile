#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

Rake::TestTask.new :test do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/plugin/*_test.rb']
end

Rake::TestTask.new 'test:integration' do |t|
  t.test_files = FileList['test/integration/*_test.rb']
end

desc 'check for style violations and test failures and build the gem'
task check: %i[rubocop test build]

task default: :build
