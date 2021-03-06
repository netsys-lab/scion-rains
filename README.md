# SCION-RAINS
[![Test](https://github.com/netsys-lab/scion-rains/actions/workflows/test.yml/badge.svg)](https://github.com/netsys-lab/scion-rains/actions/workflows/test.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/netsys-lab/scion-rains)](https://goreportcard.com/report/github.com/netsys-lab/scion-rains) 
[![Go Reference](https://pkg.go.dev/badge/github.com/netsys-lab/scion-rains.svg)](https://pkg.go.dev/github.com/netsys-lab/scion-rains)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

RAINS (RAINS, Another Internet Naming Service) is a name resolution protocol that has been designed with the aim to provide an ideal naming service for the SCION Internet architecture.
The RAINS architecture is simple, and resembles the architecture of DNS. A RAINS server is an entity that provides transient and/or permanent storage for assertions about names, and a
lookup function that finds assertions for a given query about a name, either by searching local storage or by delegating to another RAINS server.
The goal of the SCION RAINS project is to enhance and refine the existing RAINS prototype implementation on top of the newest SCION release, and make it available within the SCIONLab
network for developers and end-users to be able to use it. Additionally, the existing RAINS design will be refined with a principled approach to obtain better security and performance properties. At the heart of the redesign is a new authentication architecture for naming systems, where the standard DNSSEC-like authentication infrastructure is replaced with CA-based end-entity
PKI. Additionally, the project will make use of the DRKey system to develop mechanisms for secure and highly available RAINS communication.

## [Task 1.](https://github.com/netsys-lab/scion-rains/projects/2) Port RAINS to current SCION version

The first task is to tidy up the RAINS codebase and port a basic working version of RAINS (hereafter, the baseline) to the current SCION release.

### Milestones
- [x] Identify minor unfinished system components and [pending issues](https://github.com/netsec-ethz/rains/issues) in the original code-base, and devise a feasible [implementation and porting plan](./planning/implementation_plan.md).
- [x] Deliver [executables](https://github.com/netsys-lab/scion-rains/actions/runs/1535615463#artifacts) for end-to-end name resolution and zone management in SCION networks.
  - [x] Additionally, [manual test instructions](https://github.com/netsys-lab/scion-rains/blob/master/test/manual/) are provided to setup the core RAINS components and verify that they work as expected.

Further information:
- [x] [Official release](https://github.com/netsys-lab/scion-rains/releases/tag/v0.3.2), marking the completion of Task 1.


## [Task 2.](https://github.com/netsys-lab/scion-rains/projects/3) Re-design the data authentication architecture of RAINS based on SCION end-entity PKI system

The baseline RAINS relies on DNSSEC-style authentication that comes with inherent limitations. We seek to replace it with a [new authentication architecture](./offlineauth) based on [SCION end-entity PKI](https://github.com/cyrill-k/fpki) for better security and performance.

### Milestones
- [x] [Design documents](https://github.com/netsys-lab/scion-rains/tree/master/docs/auth-arch) with rationale and expected properties of the new authentication architecture as well as suggested modifications to the baseline RAINS
- [x] [Specifications](https://github.com/netsys-lab/scion-rains/tree/master/docs/auth-arch/tamarin) of the modified and new RAINS protocols in formal language

Further information:
- [x] [Official release](https://github.com/netsys-lab/scion-rains/releases/tag/v0.4.0), marking the completion of Task 2.

## [Task 3.](https://github.com/netsys-lab/scion-rains/projects/4) Develop a new prototype for RAINS based on CoreDNS

The legacy RAINS codebase was implemented from scratch and in an ad-hoc way. Since DNS and DNSSEC, the authentication archtecture of which is adopted by the baseline RAINS, are very complex protocols with tremendous corner cases to consider, the correct implementation of them is suprisingly [demanding and error-prone](https://ianix.com/pub/dnssec-outages.html). The baseline RAINS is far from complete and functional for real-world naming service. To this end, we decide to rebuild RAINS based on [CoreDNS](https://coredns.io), a mature and extensible framework that allows us to enable the new features of RAINS while readily enjoying the comprehensive DNS functionality.

### Milestones

- [ ] Prototype RAINS servers (recursive resolver and authoritative name server) based on CoreDNS
- [ ] Improved `rdig` tool with E2E data validation option

## [Task 4.](https://github.com/netsys-lab/scion-rains/projects/5) Implementation, integration, and testing

Finally, we will implement SCION (UDP) transport for RAINS and deploy test name servers to the SCIONLab network.

### Milestones
- [ ] RAINS servers and `rdig` with SCION transport option
- [ ] Operate test RAINS servers in SCIONLab
- [ ] Test suite for the new approach based on docker-compose 
  - [ ] Additionally, source code, specifactions, documentation and other results will be provided
