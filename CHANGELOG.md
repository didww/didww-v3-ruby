# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Breaking Changes
- rename /v3/trunks to /v3/voice_in_trunks
- rename /v3/trunk_groups to /v3/voice_in_trunk_groups
- /v3/voice_in_trunks rename relationship trunk_group to voice_in_trunk_group
- /v3/voice_in_trunk_groups relationship trunks to voice_in_trunks
- /v3/dids rename relationships trunk and trunk_group to voice_in_trunk and voice_in_trunk_group
- replace DIDWW::Client methods #trunks and #trunk_groups to #voice_in_trunks and #voice_in_trunk_groups
- v3/trunks sip configuration add media_encryption_mode_id and stir_shaken_mode_id attributes

## [2.0.0] - 2021-10-26
### Breaking Changes
- upgrade `json_api_client` version to `1.18.0` [#9](https://github.com/didww/didww-v3-ruby/pull/9)  
    Handling of 4XX responses was changed - it now raises JsonApiClient::Errors::ClientError with `detail` as error message instead of adding it into base errors.
- /v3/dids in request and response attributes pending_removal being removed in favor of billing_cycles_count.
- /v3/did_groups restriction message removed in favor of requirements relationship.
  
### Changes
- replace travis with github actions [#7](https://github.com/didww/didww-v3-ruby/pull/7) [#9](https://github.com/didww/didww-v3-ruby/pull/9)
- use rubocop 1.9.X version [#7](https://github.com/didww/didww-v3-ruby/pull/7)
- add bundle-audit [#7](https://github.com/didww/didww-v3-ruby/pull/7)
- /v3/orders request attribute items of type DID Order Item Attributes can have billing_cycles_count.
- /v3/dids added address_verification relationship.
- callbacks attributes added to /v3/orders, /v3/cdr_exports.
- /v3/proof_types read endpoints being added.
- /v3/supporting_document_templates read endpoints being added.
- /v3/requirements read endpoints being added.
- /v3/identities read, write, and delete endpoints being added.
- /v3/addresses read, write, and delete endpoints being added.
- /v3/encrypted_files read, write, and delete endpoints being added.
- /v3/proofs write, delete endpoint being added.
- /v3/permanent_supporting_documents write, delete endpoint being added.
- /v3/address_verifications read and write endpoints being added.
- /v3/requirement_validations write endpoint being added.

### Bugfixes
- fix order purchase when activesupport 6.X.X is used.

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
