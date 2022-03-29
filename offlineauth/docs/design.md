# A New Authentication Architecture for RAINS

This document provides an overview of an experimental authentication architecture developed for RAINS. For a more detailed description, please refer to the Master Thesis listed in the reference section below.

Instead of DNSSEC-style authentication that establishes a chain of trust solely within the DNS hierarchy, the new architecture introduces external trust entities, i.e., CAs in an end-entity PKI (EE-PKI), to authenticate zone authorities. This creates unique opportunitites to overcome the inherent limitations of DNSSEC in terms of security, performance, and management.

A prototype of the new designs has been implemented based on the existing RAINS codebase.

## Problem Statement

## Design Rationale

## Protocols

## Formal Model and Verification

## Prototype Implementation

## References

