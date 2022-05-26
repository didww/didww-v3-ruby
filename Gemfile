# frozen_string_literal: true
source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in didww-v3.gemspec
gemspec

if ENV['RAILS_VERSION']
  gem 'activesupport', ENV['RAILS_VERSION'], require: false
end

gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'
gem 'pry'
gem 'byebug'
gem 'awesome_print'
gem 'http_logger'
gem 'rubocop', '~> 1.28.2'
gem 'rubocop-performance'
gem 'rubocop-rake'
gem 'rubocop-rspec'
gem 'simplecov'
gem 'smart_rspec'
gem 'webmock'
gem 'bundler-audit'
