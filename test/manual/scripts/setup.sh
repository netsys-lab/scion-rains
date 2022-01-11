#!/bin/bash

# update the self delegation of the root zone in case of expiration 
../../build/keymanager selfsign ./keys/root/root -s ./keys/root/selfSignedRootDelegationAssertion.gob
