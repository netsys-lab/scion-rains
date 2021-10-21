# SCION-RAINS

RAINS (RAINS, Another Internet Naming Service) is a name resolution protocol that has been designed with the aim to provide an ideal naming service for the SCION Internet architecture.
The RAINS architecture is simple, and resembles the architecture of DNS. A RAINS server is an entity that provides transient and/or permanent storage for assertions about names, and a
lookup function that finds assertions for a given query about a name, either by searching local storage or by delegating to another RAINS server.
The goal of the SCION RAINS project is to enhance and refine the existing RAINS prototype implementation on top of the newest SCION release, and make it available within the SCIONLab
network for developers and end-users to be able to use it. Additionally, the existing RAINS design will be refined with a principled approach to obtain better security and performance proper-
ties. At the heart of the redesign is a new authentication architecture for naming systems, where the standard DNSSEC-like authentication infrastructure is replaced with CA-based end-entity
PKI. Additionally, the project will make use of the DRKey system to develop mechanisms for secure and highly available RAINS communication.

## Task 1. Port RAINS to current SCION version
The first task is to tidy up the RAINS codebase and port a basic working version of RAINS (hereafter, the baseline) to the current SCION release.

### Milestones
- [x] Identify minor unfinished system components and [pending issues](https://github.com/netsec-ethz/rains/projects/5) in the current code-base, and devise a feasible [implementation and porting plan](./planning/implementation_plan.md).
- [x] Deliver [executables](https://github.com/netsec-ethz/rains) for end-to-end name resolution and zone management in SCION networks.

## Task 2. Re-design the data authentication architecture of RAINS based on SCION end-entity PKI system

The baseline RAINS relies on DNSSEC-style authentication that comes with inherent limitations. We seek to replace it with a new authentication architecture based on SCION end-entity PKI for better security and performance.

### Milestones
- [ ] Design documents with rationale and expected properties of the new authentication architecture as well as suggested modifications to the baseline RAINS
- [ ] Specifications of the modified and new RAINS protocols in formal language

## Task 3. Make use of DRKey system to develop mechanisms for secure and highly available RAINS communication

Internet naming systems are inviting targets for DoS attacks. This task aims to leverage the DRKey system to develop mechanisms that guarantee availability of RAINS in presence of DoS attacks.

### Milestones

- [ ] Design documents of integrating DRKey into RAINS
- [ ] Refined protocol specifications

## Task 4. Implementation, integration, and testing

Finally, we will implement and test the new features on top of the baseline RAINS, and deploy it to the SCIONLab network.

### Milestones
- [ ] A complete RAINS codebase that implements above-mentioned new features
- [ ] Design, test, and preliminary evaluation reports of RAINS running in SCIONLab
