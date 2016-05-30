# How It Works

## Part One: Config Checks

Goal: ensure valid config data and transaction journal.

Config checks will fail if the transaction journal or config file is
improperly formatted.

### Decipher Entity Config Sections from Price Data Sections

- split config.toml into entities (accounts) and prices
  (currencies/assets)
  - detect entities section by scanning section keys for `base-currency`
    and `open`. If no section keys are found, assume it is an entity.
  - detect prices section by scanning section header for `Assets`,
    and section keys for `price-file` or ISO dates

### Entities

- check entities for correct syntax
  - check that no top-level [entity] name, uppercased for
    case-insensitivity, is used more than once
  - check that each top-level [entity], if quoted then unquoted, does
    not contain invalid Nightscape syntax
      - no whitespace
      - no special chars except `_` and `-`
  - check that only keys appearing under each [entity] are `base-currency`
    and `open`
- parse entities to establish seed hash of entities and subaccounts
  - if the [entity] contains [entity.subaccount.hashes], isolate entity
    from the listed subaccounts
  - uppercase all entity names and subaccounts for case-insensitivity
- parse transaction journal
  - check that all entities (uppercased) in use have been properly
    established
  - check that each posting only involves one entity
  - check, for each entity, existence of an `open` directive in
    entities config
  - check, for each subaccount, existence of an `open` directive in
    entities.subaccount config
    - when both the entity and its related subaccount contain an `open`
      directive, ensure the subaccount date range falls within valid
      entity date range
  - ensure transaction dates involving each entity with an `open`
    directive fall within valid date range
  - ensure transaction dates involving each subaccount with an `open`
    directive fall within valid date range

### Prices

- lookup base-currency for each transaction posting
- if asset code given in the transaction journal differs from the
  controlling entity’s base-currency, ensure price config contains
  valid price data for the asset used on the date given
  - check transaction journal for `@` syntax
  - if no `@` syntax, check config for ISO date (manual) price data entry
  - if no ISO date (manual) price data entry in config, check config
    for price data file


## Part Two: Initialize Data Structures

### Entity Setup

- Initialize data structure (TBD) for each entity declared in the config

### Equity Setup
