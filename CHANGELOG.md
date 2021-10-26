# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2021-10-26
### Changes
- replace travis with github actions [#7](https://github.com/didww/didww-v3-ruby/pull/7) [#9](https://github.com/didww/didww-v3-ruby/pull/9)
- use rubocop 1.9.X version [#7](https://github.com/didww/didww-v3-ruby/pull/7)
- add bundle-audit [#7](https://github.com/didww/didww-v3-ruby/pull/7)

### Bugfixes
- fix order purchase when activesupport 6.X.X is used.
- fix BigDecimal 2 support for ruby 2.7+.

## [1.3.0] - 2018-09-03
### Changes
- Add Capacity Pool and Shared Capacity Group resources
- Add Capacity Pool and Shared Capacity Group relationships to DID
- Add Quantity based pricings and Capacity type Order Item

## [1.2.0] - 2018-04-25
### Changes
- add number selection feature

## [1.1.0] - 2018-03-05
### Changes
- add Pop resource
- Remove old trunk.preferred_server property
- Add max_transfers and max_30x_redirects to sip_configurations
- Added custom user-agent header

## [1.0.0] - 2017-12-05
- initial release
