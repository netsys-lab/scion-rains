# Overview

To ensure smooth implementation and integration, we will not squeeze all coding efforts into the last stage of the project. Instead, the implementation of new components and functionality will start as soon as preliminary designs are ready.

We plan to progress in 4 phrase, in line with the project schedule.

## Phase 1: Preparing the baseline version

- Est. duration: 0.5 month
- Tasks
  - Resolve the identified [urgent issues](./issue_tracking.md)
  - Build with the current Go version used by SCIONLab
  - Integration test

## Phase 2: Implementing the new data authentication architecture

- Est. duration: 3 months
- New system components (preliminary)
  - ACME-style client
  - Zone manager (TBC: separate from RAINS server?)
  - CA server add-on
  - Log server add-on
- Tasks
  - Specify RAINS certificate format and extension based on X.509
  - Integrate with F-PKI (the end-entity PKI used by SCION)
  - Implement certificate issuance and management protocols
  - Replace assertion signing and validation logic of the baseline with the new design

## Phase 3: Implementing DRKey-based secure communication channels for name resolution

- Est. duration: 1.5 months
- Tasks
  - Adapt the data model of RAINS to the new design
  - Incorporate DRKey key establishment protocols into RAINS 
  - Specify and implement message encrytion and authentication schemes

## Phase 4: Final integration, deployment, and testing

- Est. duration: 2 months
- Tasks
  - Integrate all components
  - Deploy to SCIONLab
  - Evaluation plan (TBD)
  - Resolve [non-urgent issues](./issue_tracking.md)
