# Examples

All examples read the API key from the `DIDWW_API_KEY` environment variable and run against the sandbox.

## Prerequisites

- Ruby 3.3+
- Bundler
- DIDWW API key for sandbox account

## Environment variables

- `DIDWW_API_KEY` (required): your DIDWW API key. `webhook.rb` runs offline and does not need it.
- `DIDWW_README_PRODUCTION_API_KEY` (optional for `test_readme.rb`): a production API key for the README's production configuration, which then runs read-only (a read token, the balance, the countries and one price lookup); without it that check is skipped.
- `DIDWW_README_PROXY_URL` (optional for `test_readme.rb`): an HTTP(S) proxy the README's proxy snippets are run through; without it they are skipped. The README's Rails webhook controller runs when `actionpack` is in the bundle.

## Install

From the repository root:

```bash
bundle install
```

## Run an example

From the repository root:

```bash
DIDWW_API_KEY=your_api_key ruby examples/orders_nanpa.rb
```

### Pass an argument

`upload_file.rb` takes an optional file (default `examples/sample.pdf`), `prices_lookup.rb` an optional number and `prices_download.rb` an optional directory:

```bash
DIDWW_API_KEY=your_api_key ruby examples/upload_file.rb path/to/passport.pdf
DIDWW_API_KEY=your_api_key ruby examples/prices_lookup.rb 18005550123
```

## Available examples

| Script | Description |
|---|---|
| [`balance.rb`](balance.rb) | Fetches and prints current account balance and credit. |
| [`countries.rb`](countries.rb) | Lists countries, filters them by name, and fetches one country by ID. |
| [`regions.rb`](regions.rb) | Lists the regions of a country with the included country and fetches one region. |
| [`did_groups.rb`](did_groups.rb) | Lists DID groups with included SKUs and shows group details. |
| [`did_history.rb`](did_history.rb) | Lists DID ownership history events (last 90 days), filtered by action, number and date. |
| [`dids.rb`](dids.rb) | Lists DIDs and updates the first one: assigns a SIP trunk, a capacity pool, a capacity limit and a description. |
| [`did_trunk_assignment.rb`](did_trunk_assignment.rb) | Assigns a DID to a trunk, then to a trunk group (the trunk is cleared: they are exclusive), then restores the DID's routing and deletes the created trunk and group. |
| [`did_sms_routing.rb`](did_sms_routing.rb) | Routes a DID's inbound SMS to an SMS trunk, then to an SMS trunk group (exclusive assignment), and restores the DID's SMS routing. |
| [`did_reservations.rb`](did_reservations.rb) | Reserves an available DID, lists and finds reservations, and deletes the reservation. |
| [`capacity_pools.rb`](capacity_pools.rb) | Lists capacity pools with included shared capacity groups and qty-based pricings, and finds one pool. |
| [`shared_capacity_groups.rb`](shared_capacity_groups.rb) | Creates a shared capacity group in a capacity pool, lists groups, updates the group and deletes it. |
| [`orders.rb`](orders.rb) | Lists recent orders, orders a DID by SKU and cancels (deletes) that order. |
| [`orders_sku.rb`](orders_sku.rb) | Orders DIDs by SKU and quantity (one `did_order_items` item with `sku_id` and `qty`). |
| [`orders_available_dids.rb`](orders_available_dids.rb) | Orders a specific available DID using the SKU of its included DID group. |
| [`orders_reservation_dids.rb`](orders_reservation_dids.rb) | Reserves a DID and then places an order from that reservation. |
| [`orders_nanpa.rb`](orders_nanpa.rb) | Orders a DID number by NPA/NXX prefix. |
| [`orders_capacity.rb`](orders_capacity.rb) | Buys capacity channels with a capacity order item. |
| [`orders_all_item_types.rb`](orders_all_item_types.rb) | Places one order with the three DID item variants: by SKU and quantity, an available DID, and a reserved DID. |
| [`orders_emergency.rb`](orders_emergency.rb) | Reads server-created emergency orders among the recent orders and follows an emergency calling service to its order. |
| [`trunks.rb`](trunks.rb) | Lists voice IN trunks with their configurations and finds one, creates a SIP trunk and a PSTN trunk, updates both and deletes both. |
| [`voice_in_trunk_groups.rb`](voice_in_trunk_groups.rb) | Creates two trunks and a trunk group with them, lists groups with their trunks, renames the group, and deletes the group and the trunks. |
| [`voice_in_trunk_sip_registration.rb`](voice_in_trunk_sip_registration.rb) | End-to-end SIP registration flow: create with `enabled_sip_registration: true`, rename, disable by setting `host`, re-enable by toggling the flag. The SDK keeps the dependent fields (`host`, `port`, `use_did_in_ruri`) aligned with the server's validation rules automatically. |
| [`voice_out_trunks.rb`](voice_out_trunks.rb) | Lists, creates, updates and deletes voice out trunks (requires account configuration). |
| [`sms_trunks.rb`](sms_trunks.rb) | Lists SMS trunks, creates an HTTP IN trunk, updates its configuration and deletes it; shows how to rotate generated credentials. |
| [`sms_trunk_groups.rb`](sms_trunk_groups.rb) | Creates two inbound SMS trunks, groups them by priority, lists groups and deletes the group with its trunks. |
| [`sender_id_verifications.rb`](sender_id_verifications.rb) | Lists Sender ID verifications with their SMS trunks, renames an active one and restores its name. |
| [`identity_address_proofs.rb`](identity_address_proofs.rb) | Creates an identity and an address, uploads an encrypted file, creates proofs for both, prints the verified flags, and deletes the address and the identity. |
| [`address_verifications.rb`](address_verifications.rb) | Lists address verifications with reject_comment / external_reference_id. |
| [`upload_file.rb`](upload_file.rb) | Encrypts a file with the DIDWW public keys and uploads it; prints the encrypted file ID. |
| [`exports.rb`](exports.rb) | Creates and lists CDR exports, with external_reference_id. |
| [`exports_sms.rb`](exports_sms.rb) | Creates SMS-In and SMS-Out exports with their filters and reads a completed one. |
| [`emergency_requirements.rb`](emergency_requirements.rb) | Lists emergency service requirements per country/number_type. |
| [`emergency_requirement_validations.rb`](emergency_requirement_validations.rb) | Pre-validates an emergency order triple (requirement + address + identity). |
| [`emergency_verifications.rb`](emergency_verifications.rb) | Lists emergency verifications and shows how to create one. |
| [`emergency_calling_services.rb`](emergency_calling_services.rb) | Lists customer emergency calling services and shows how to cancel one. |
| [`emergency_scenario.rb`](emergency_scenario.rb) | End-to-end: find DID → check requirements → validate → create verification → get service. |
| [`prices_lookup.rb`](prices_lookup.rb) | Looks up Voice IN, Voice OUT, SMS OUT (A2P, P2P, OTP) and SMS IN prices for a number. |
| [`prices_download.rb`](prices_download.rb) | Downloads the gzipped Voice IN price file, re-checks it with If-Modified-Since and reads a few rows. |
| [`includes.rb`](includes.rb) | Reads regions, DID groups, available DIDs (nested include) and DIDs with included relationships, and shows how an included and a not-included relationship are read. |
| [`webhook.rb`](webhook.rb) | Signs a sample callback the way DIDWW does and validates it, and a tampered copy, with `DIDWW::Callback::RequestValidator`. Runs offline. |
| [`test_readme.rb`](test_readme.rb) | Runs the code snippets of the gem's README against the sandbox, one check per snippet, and cleans up; prints `Results: N passed, M failed` and exits 1 when a check fails. |

## Troubleshooting

If `DIDWW_API_KEY` is missing, examples fail fast with:

`Please set DIDWW_API_KEY`
