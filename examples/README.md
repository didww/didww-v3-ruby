# Examples

All examples read the API key from the `DIDWW_API_KEY` environment variable.

## Prerequisites

- Ruby 3.3+
- Bundler
- DIDWW API key for sandbox account

## Environment variables

- `DIDWW_API_KEY` (required): your DIDWW API key

## Install

```bash
cd examples && bundle install
```

## Run an example

```bash
DIDWW_API_KEY=your_api_key ruby examples/orders_nanpa.rb
```

## Available examples

### Core Resources
| Script | Description |
|---|---|
| [`balance.rb`](balance.rb) | Fetches and prints current account balance and credit. |
| [`countries.rb`](countries.rb) | Lists countries, demonstrates filtering, and fetches one country by ID. |
| [`regions.rb`](regions.rb) | Lists regions with filters/includes and fetches a specific region. |
| [`did_groups.rb`](did_groups.rb) | Fetches DID groups with included SKUs and shows group details. |
| [`dids.rb`](dids.rb) | Updates DID routing/capacity by assigning trunk and capacity pool. |
| [`exports.rb`](exports.rb) | Lists CDR exports and their details. |

### Voice In (Inbound)
| Script | Description |
|---|---|
| [`voice_in_trunks.rb`](voice_in_trunks.rb) | Lists voice in trunks and their configurations. |
| [`voice_in_trunk_groups.rb`](voice_in_trunk_groups.rb) | CRUD for trunk groups with trunk relationships. |

### Voice Out (Outbound)
| Script | Description |
|---|---|
| [`voice_out_trunks.rb`](voice_out_trunks.rb) | CRUD for voice out trunks (requires account config). |

### Capacity Management
| Script | Description |
|---|---|
| [`capacity_pools.rb`](capacity_pools.rb) | Lists capacity pools with included shared capacity groups. |
| [`shared_capacity_groups.rb`](shared_capacity_groups.rb) | Creates a shared capacity group in a capacity pool. |

### Orders - Basic
| Script | Description |
|---|---|
| [`orders.rb`](orders.rb) | Lists orders and creates/cancels a DID order using live SKU lookup. |
| [`orders_nanpa.rb`](orders_nanpa.rb) | Orders a DID number by NPA/NXX prefix. |
| [`orders_by_sku.rb`](orders_by_sku.rb) | Creates a DID order by SKU resolved from DID groups. |
| [`orders_capacity.rb`](orders_capacity.rb) | Purchases capacity by creating a capacity order item. |

### Orders - Advanced
| Script | Description |
|---|---|
| [`orders_available_dids.rb`](orders_available_dids.rb) | Orders an available DID using included DID group SKU. |
| [`orders_reservation_dids.rb`](orders_reservation_dids.rb) | Reserves a DID and then places an order from that reservation. |
| [`orders_all_item_types.rb`](orders_all_item_types.rb) | Creates a DID order with all item types: by SKU, available DID, and reservation. |

### DID Management
| Script | Description |
|---|---|
| [`did_reservations.rb`](did_reservations.rb) | Lists DID reservations and available DIDs. |
| [`did_trunk_assignment.rb`](did_trunk_assignment.rb) | Demonstrates exclusive trunk/trunk group assignment on DIDs. |

### Compliance & Verification
| Script | Description |
|---|---|
| [`identities_and_proofs.rb`](identities_and_proofs.rb) | Creates identities, addresses, and demonstrates proof workflow. |

## Troubleshooting

If `DIDWW_API_KEY` is missing, examples fail fast with:

`Please set DIDWW_API_KEY`
