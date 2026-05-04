# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.0.1] - 2026-04-30
### Added
- Complete the 2026-04-16 `SipConfiguration` attribute set that was missed during the 2026-04-16 rollout (and is not present in the public Postman collection — server form is the source of truth):
  - `enabled_sip_registration` (bool) — enables SIP registration; the API generates `incoming_auth_*` credentials when set true and requires `port` to be blank.
  - `use_did_in_ruri` (bool) — uses DID number in R-URI; requires SIP registration to be enabled.
  - `network_protocol_priority` (string enum) — `force_ipv4` / `force_ipv6` / `any` / `prefer_ipv4` / `prefer_ipv6`. Constants exposed as `NETWORK_PROTOCOL_PRIORITY_*` and `NETWORK_PROTOCOL_PRIORITIES`.
  - `diversion_inject_mode` (string enum) — `none` / `did_number`. Constants exposed as `DIVERSION_INJECT_MODE_*` and `DIVERSION_INJECT_MODES`.
  - `cnam_lookup` (bool) — enables CNAM resolution for inbound calls.
- `SipConfiguration#incoming_auth_username` and `#incoming_auth_password` — read-only server-generated SIP authentication credentials returned on `voice_in_trunks` when `enabled_sip_registration` is true.
- `ComplexObject::Base.property` accepts `read_only: true`. Read-only attributes are still parsed from server responses but are stripped from the JSON:API write payload, so round-tripping a loaded configuration through PATCH no longer triggers `400 Param not allowed`.

## [6.0.0] - 2026-04-24
Support for DIDWW API version **2026-04-16**. The gem now sends `X-DIDWW-API-Version: 2026-04-16` with every request by default. Users staying on API `2022-05-10` should pin to the [`2022-05-10`](https://github.com/didww/didww-v3-ruby/tree/2022-05-10) branch (5.x).

### Breaking Changes
- Default `X-DIDWW-API-Version` header is now `2026-04-16`.
- Resource `requirement_validations` renamed to `address_requirement_validations`.
- Resource `requirements` renamed to `address_requirements`.
- `AddressRequirementValidation#requirement` relationship renamed to `address_requirement`.
- `DidGroup#requirement` relationship renamed to `address_requirement`.
- `DidReservation#expire_at` renamed to `expires_at`.
- `EncryptedFile#expire_at` renamed to `expires_at`.
- `AddressVerification#reject_reasons` is now an array of strings.
- Dropped `sms_out` from `DidGroup` features.
- `EncryptedFile` POST now accepts a single file per request.
- `Export` year/month filters replaced with `from`/`to` datetime range (`from` inclusive, `to` exclusive).
- `VoiceInTrunk` SIP configuration gains `diversion_relay_policy`.
- Attribute values standardized to lowercase `snake_case` (status/area-level enums, etc.).
- `Order#cancelled?` renamed to `canceled?`; `Order::STATUS_CANCELLED` → `STATUS_CANCELED` to match wire format (`status: "canceled"`).
- `VoiceOutTrunk`: flat credentials (`username`/`password`/`auth_type`) replaced with a polymorphic `authentication_method` relationship. Supported types: `CredentialsAuthenticationMethod`, `IpAuthenticationMethod`, `CredentialsAndIpAuthenticationMethod`, `TwilioAuthenticationMethod`, and `GenericAuthenticationMethod` (forward-compatible fallback).
- `DidGroup`: removed `features_human` and `FEATURES` constant.

### Added
- New resource `DidHistory` (`/v3/did_history`) with `meta.billing_cycles_count_changed`.
- New resource `EmergencyRequirement` (`/v3/emergency_requirements`).
- New resource `EmergencyRequirementValidation` (`/v3/emergency_requirement_validations`).
- New resource `EmergencyCallingService` (`/v3/emergency_calling_services`) with `address` has-one relationship.
- New resource `EmergencyVerification` (`/v3/emergency_verifications`).
- `external_reference_id` attribute on `Address`, `AddressVerification`, `Export`, `EmergencyVerification`, `Order`, `PermanentSupportingDocument`, `Proof`, `SharedCapacityGroup`, `VoiceInTrunkGroup`, `VoiceInTrunk`, `VoiceOutTrunk`.
- PATCH support for `external_reference_id` on `/v3/address_verifications/:id`, `/v3/exports/:id`, `/v3/emergency_verifications/:id`.
- `VoiceOutTrunk`: `emergency_enable_all`, `rtp_timeout`, `emergency_dids` has-many relationship, status predicate helpers.
- `Did`: `emergency_enabled`, `emergency_calling_service` / `emergency_verification` / `identity` has-one relationships, PATCH support for unassigning `emergency_calling_service`.
- `Identity`: `birth_country` has-one relationship.
- `DidGroup`: new features `p2p`, `a2p`, `emergency`, `cnam_out`; `service_restrictions` attribute.
- `AddressVerification`: `reject_comment` attribute.
- `Order`: new `EmergencyOrderItem` complex object.
- Status predicate helpers on `VoiceOutTrunk`, `EmergencyCallingService`, `AddressVerification`, `EmergencyVerification`, and `Order`.
- `Export` exposes `STATUS_PENDING` and `STATUS_PROCESSING`.
- `randomize_cli` added to `OnCliMismatchAction` constants.
- Examples for all new 2026-04-16 resources and an end-to-end `emergency_scenario` example.

### Changed
- Unknown `authentication_method` types are wrapped in `Generic` for forward compatibility.
- Resource-level meta support for `EmergencyCallingService` and `EmergencyRequirement`.
- `ExportFilters` from/to semantics clarified (from=inclusive, to=exclusive).
- Examples: fixtures use RFC 5737 documentation IPs (`203.0.113.0/24`); `SecureRandom.hex(4)` used for random IDs.
- Shared rspec examples extracted for PATCH `external_reference_id` and requirement validations POST→204.

### Fixed
- Declare `has_one :address` on `EmergencyCallingService` to mirror server.
- `features_human` falls back to raw key for unknown features (superseded by removal in 6.0).

## [5.3.1]
### Fixed
- Correct `VoiceOutTrunk` constant wire values to match API responses.

## [5.3.0]
### Added
- `DIDWW::Client.customize_connection` to allow customizing the Faraday connection (e.g. proxy, timeouts, custom middleware).

## [5.2.0]
### Changes
- Extract status predicate methods into `HasStatusHelpers` concern.
- Merge shared auth header logic into `BaseMiddleware`, `JsonapiMiddleware` inherits and adds `Content-Type`.
- Replace 29 resource accessor methods with `RESOURCE_CLASSES` hash and `define_method`.
- Document date and datetime field types in README.

### Fixed
- Fix date type attributes: use `:time` for ISO 8601 timestamps.
- Add missing resource fields: `reference`, `permanent`, `iso`, `contact_email`.
- Add `requirement` relationship to `DidGroup`.
- Skip `Api-Key` header on `public_keys` endpoint.
- Add `User-Agent` header to export download.
- Use timing-safe comparison for callback signature validation.
- Fix `is_expired` boolean changed to `expires_at` date on `Proof`.

## [5.1.0]
### Added
- `X-DIDWW-API-Version` header sent with requests.
- Exclusive relationship auto-nullification for DID `voice_in_trunk`/`voice_in_trunk_group`.
- Export gzip decompression support (`.csv.gz`).
- `VoiceOutTrunk` CRUD tests and fixtures.

### Changes
- Rename test fixtures from `sample_N` to self-descriptive names.

## [5.0.0]
### Breaking Changes
- Remove H323 and IAX2 trunk configuration support.
- Update dependencies and CI for current Ruby/Rails versions.

### Added
- Add missing relationship declarations and tests for included resources.

### Fixed
- Fix compatibility with `json_api_client` 1.23.0 and newer Ruby.

## [4.1.0]
### Breaking Changes
- removed DIDWW::Resource::DidGroup::FEATURE_VOICE in favor DIDWW::Resource::DidGroup::FEATURE_VOICE_IN and DIDWW::Resource::DidGroup::FEATURE_VOICE_OUT [#42](https://github.com/didww/didww-v3-ruby/pull/42)
- removed DIDWW::Resource::DidGroup::FEATURE_SMS in favor of DIDWW::Resource::DidGroup::FEATURE_SMS_IN and DIDWW::Resource::DidGroup::FEATURE_SMS_OUT [#42](https://github.com/didww/didww-v3-ruby/pull/42)

## [4.0.0]
### Breaking Changes
- /v3/did_groups removed `local_prefix` attribute
### Added
- /v3/nanpa_prefixes endpoints being added.

### Changes
- /v3/orders endpoints being updated. Added nanpa_prefix_id attribute for DID order item.

## [3.0.0]
### Breaking Changes
- /v3/trunks being moved to /v3/voice_in_trunks.
- /v3/trunk_groups being moved to /v3/voice_in_trunk_groups.
- /v3/cdr_exports being moved to /v3/exports. Endpoint now allows generating both inbound and outbound CDRs export.
- /v3/exports result file will be CSV archived in GZIP.
- Callbacks payload for exports being changed: value of type attribute is changed to exports.
- /v3/exports export_type required attribute being added to request and response with possible values: cdr_in, cdr_out.
- /v3/exports filters attribute being removed from response.
- /v3/did_groups filter features allowed values to be changed to sms_in, sms_out, voice_in, voice_out, t38.
- /v3/did_groups response value of features attribute to be changed to sms_in, sms_out, voice_in, voice_out, t38.
- /v3/available_dids filter did_group.features allowed values being changed to sms_in, sms_out, voice_in, voice_out, t38.
- /v3/dids rename trunk_group relationship to voice_in_trunk_group with type voice_in_trunk_groups.
- /v3/dids rename trunks relationship to voice_in_trunks with type voice_in_trunks.

### Changes
- /v3/voice_out_trunks endpoints being added.
- /v3/voice_out_trunk_regenerate_credentials endpoint being added.
- /v3/voice_in_trunks SIP configuration additional attributes being added to request and response: media_encryption_mode, stir_shaken_mode, allowed_rtp_ips.
- /v3/dids filter add filter did_group.features with allowed values: sms_in, sms_out, voice_in, voice_out, t38.
- Callbacks allow receiving events about /v3/voice_out_trunks status change.

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
