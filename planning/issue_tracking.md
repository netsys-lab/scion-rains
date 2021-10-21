# Background

This file serves to track the [pending issues](https://github.com/netsec-ethz/rains/projects/5) in the current RAINS codebase as well as newly discovered ones.

We classify issues into *Urgent* (pertinent to the correct functioning of the baseline version) and *Non-urgent* (could be resolved at a later time).

This allows for effective planning for the implementation and integration process.

# Classification

## Urgent

- Go 1.9 build and test #113

- Testing and CI for internal components of rainsd / rainspub #100

- Support for SCION UDP #97, #98 (these issues seem to be partially addressed, to confirm with SCIONLab team with their current status)

## Non-urgent

- Support for SCION addresses and PKI #11 (deferred because of the re-design of RAINS authentication architecture)

- Testing and CI for SCION integration #160

- Create a zone manager for zone authorities to automate management routines, #134, #135 (the zone manager will also integrate many functions from the new authentication architecture)

- Publishing content for zones larger than the maximum msg size #179

## Unclassified (double check with SCIONLab team)

- Prometheus integration #102

- Unexpected behavior of handling HostNotFoundError and name delimtation (may be related to issue #221)
