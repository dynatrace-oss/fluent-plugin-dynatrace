#!/usr/bin/env rake
# frozen_string_literal: true

# Copyright 2021 Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
