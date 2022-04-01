# Tamarin model

Here's a summary of the Tamarin [model](NewDlg.spthy) for the [NewDlg protocol](../figures/NewDlg.png).

### Model / Rules:

4 entities: child, parent, ca, log

child, parent, ca are in different states of the protocol: modeled with state facts e.g. `C_St_1()`

log server only has one init and then produces a persistent state fact.

Before init, public key is generated with `Register_pk` rule. Note that there is no `Unique()` fact for the identity.

Child and Parent have an Identity: `C`, `P` and a public key `Ckey`, `Pkey`.
The identity is their zone, so for instance `ethz = C` , `ch = P` for zone `ethz.ch`

Since there can be multiple parents (with different keys) for the same `P`, there is a `ParentAuthentication` rule.
This rule has the `Unique` fact so we assume only ever one authentic parent for a zone. Otherwise properties like obtaining a 2nd certificate for
an independent childzone can be broken with a second authentic parent. In the real protocol an attacker can not produce another authentic parent
either. Even a malicious CA can not do that by signing a certificate for the parent because by induction it also needs a certificate for that parent
and some parent will eventually be authenticated via dnssec instead of a certificate. (Root and TLDs)


### Channels :

Secure channels are modeled with `Secure_send` and `Secure_recv`.
But in the reveal rules we differentiate by revealing a channel or a key. So we can prove lemmas only requiring that
a key must not be compromised essentially allowing insecure channels.

### Restrictions:

The log is never compromised in our model. Besides the restricion `LogNeverCompromised`
we have two restricions `AbsenceCheck1` and `AbsenceCheck2`. These make sure that the log always answers correctly to
a CAs query for certificates for a certain zone.


###Lemmas:

**sanity checks**: `ChildFinishSuccess`, `ChildFinishFailed` (first register a cert, then try to register another)

**Property1 and 2** are the lemmas we are interested about that should capture our security goals for this system.

All other lemmas are not really useful, can be considered as more sanitiy checks mabye.


**Property1 states**: If there exists a cert for `C`,`P` in the log and the authentic parent `P`, `Pkey` exists, and no entitiy has been compromised so far then:
It is not possible to get another cert for `C`,`P` into the log if only the `Pkey` is revealed (this means also CA key can not be revealed, channels can).

This is supposed to capture malicious or compromised parents who should not be able to get a second certificate in our design. The parent can not get a second certificate from a CA and therefore can not pass the log server check.
The parent could just sing the certificate itself , acting as the CA, which is why we have the `!CA()` fact after a CA init. The log server checks this.

**Note Property1: Bound:**
```
& (All role X Y idX idY #j #k.
Init(role, X, idX)@j & Init(role, Y, idY)@k
==> ((#j = #k))
)
```
It would be nice to prove propery1 without this bound.

**Property2 states:** If there exists a cert for `C`,`P` in the log and the authentic parent `P`, `Pkey` exists, and no entitiy has been compromised so far then:
It is not possible to get another cert for `C`,`P` into the log if `Pkey` is not revealed (other keys can be revealed (CA) + chanels too ) AND the parent has not started the
protocl for `C`,`P` .

This lemma is supposed to capture malicious or compromised CAs. Without the parent being compromised too they should not be able to put a second certificate in the log.
The parent could also be malicious, essentially just executing the protocol with the certificate from the compromised CA. An honest parent wouldn't do that which is why we need the assumption `not(Started('Parent', C, P))` too.


**Note Property1+2:**
The `not(Init())` statements in property1 and 2 make sure that the existing certificate in the log is generated with the "event" rule `ExistingCertInLog`. And make sure there are no unfinished protocol executions in the model that the attacker could consider.




### attacks in general :

For an attack (getting a second certificate for an existing independent subzone) we need the authentic parent signing the request as well as a CA signing the request. A CA needs to be compromised for that because a honest CA is always listenting to the answer from the log (conflict exists) and not signing a certificate.
The parent could just act as CA, essentially signing the certificate itself, which is why we have the `!CA()` fact after a CA init rule.

If the model allows a compromised CA, then an attack is possible with a malicious parent,  because the model does not know that an honest parent wouldn't start the protocol or sign a request for an existing independent child. This is why property 2 has the states that the parent has not started the protocol with C, P .


### other attacks ( `NoConflictingCertsInLog` lemma which falsifies) :

A parent sends to messages two a CA, both before sending a message to the log to add the certificates. The CAs will respond with no conflict in both cases, now the parent
has two certificates to add to the log.

In the real world this could very well be used by a parent to create a second certificate for themself. This is why we have the assumption that before a child zone has obtained a cert, no entity was malicious or compromised.


### OUTPUT:

`tamarin-prover --prove NewDlg.spthy`

````
==============================================================================
summary of summaries:

analyzed: NewDlg.spthy

ChildFinishSuccess (exists-trace): verified (12 steps)
ChildFinishFailed (exists-trace): verified (29 steps)
agreement (all-traces): verified (96 steps)
AddedToLog (all-traces): verified (9 steps)
CompromisedParent (all-traces): verified (10 steps)
MaliciousParent (all-traces): verified (37 steps)
correctness (all-traces): verified (37 steps)
NoConflictingCertsInLog (all-traces): falsified - found trace (29 steps)
Property (all-traces): verified (6960 steps)
Property2 (all-traces): verified (6649 steps)

==============================================================================
