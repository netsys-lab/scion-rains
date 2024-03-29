# Test RAINS server in SCIONLAB

There are now two authoritative [scion-coredns](https://github.com/netsys-lab/scion-coredns/tree/rhine) RAINS test server running in [SCIONLab](https://www.scionlab.org/), under `19-ffaa:1:fe4,127.0.0.1` (port 53) and under `17-ffaa:1:1008,127.0.0.1` (also port 53) respectively.

For details on how to set up a SCIONLab user AS, see
[here](https://docs.scionlab.org/).

## Resolver config

To make use of this name server from within a SCIONLab user AS,
[scion-sdns](https://github.com/netsys-lab/scion-sdns) can be
configured as a recursive resolver for that AS.

The `config.yml` file for `scion-sdns` needs at least the following:

```yaml
# Address to bind to for the DNS server
bind = "0.0.0.0:53"

# Enable SCION
scion = true

# RAINS certificate to validate RRs with
cacertificatefile = "/path/to/CACert.pem"

# Root zone SCION servers
rootscionservers = [
"17-ffaa:1:1008,127.0.0.1:53",
"19-ffaa:1:fe4,127.0.0.1:53"
]

# What kind of information should be logged, Log verbosity level [crit,error,warn,info,debug]
loglevel = "debug"

# List of locations to recursively read blocklists from (warning, every file found is assumed to be a hosts-file or domain list)
blocklistdir = "bl"

# Which clients allowed to make queries
accesslist = [
"0.0.0.0/0",
"::0/0"
]
```

The `certificatefile` field should point to a local copy of the
[current SCIONLab RAINS root
certificate](https://github.com/netsys-lab/scion-rains/blob/master/testdata/scionlab/CACert.pem)
(valid until August 2023).

Note: For `scion-sdns` to be able to listen on port 53, it might be
necessary to `systemctl stop
[systemd-resolved.service](https://systemd.network/systemd-resolved.service.html)`. This
may in turn impact regular DNS name resolution on the host.

Change the `nameserver` entry in `/etc/resolv.conf` to the IP address
of the `scion-sdns` recursive resolver. A typical SCIONLab user AS
runs on just a single host, on which the resolver should be deployed
as well. In that case, `/etc/resolv.conf` should simply point to `localhost`:

```
nameserver 127.0.0.1
```

At this point, you can use a tool like `dig` to test whether you have
set up everything correctly.

`dig TXT rains.scionlab.` should return the following

```
$ dig TXT rains.scionlab.

; <<>> DiG 9.11.3-1ubuntu1.17-Ubuntu <<>> TXT rains.scionlab.
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37687
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: b823ffdb5860fe6125738a7f23a22903591a456eb8c11ab78beb7a26c2a1ca9c0b90cd9b6373b854 (good)
;; QUESTION SECTION:
;rains.scionlab.                        IN      TXT

;; ANSWER SECTION:
rains.scionlab.         3600    IN      TXT     "scion=19-ffaa:1:fe4,127.0.0.1"
rains.scionlab.         3600    IN      RRSIG   TXT 13 2 3600 20221011143250 20220907130719 60887 . 2RzauAFXZtL/kvvwRxMNA7M1aX+maMTi40t1Ar884r/PNUijlB6yyBCZ 8Zg1lFnMW5pr/f74QFra5S8GupXe5Q==

;; Query time: 200 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Wed Sep 07 16:42:09 UTC 2022
;; MSG SIZE  rcvd: 224
```


## DNS-enabled SCION apps

With the merging of [PR #230](https://github.com/netsec-ethz/scion-apps/pull/230), the DNS-enabled SCION apps can now directly be built from the [upstream repository](https://github.com/netsec-ethz/scion-apps) via `make -j build`.

(Our own fork of the SCION apps can still be found [here](https://github.com/netsys-lab/scion-apps).)

## Demo Services

There is an experimental `echo` service listening on port 1337 at
`echoservice.thorben.scionlab`.

Once `scion-sdns` is set up and at least the `scion-netcat` binary
from the DNS-enabled SCION apps has been built, you can try 

```bash
echo "The Horse Does Not Eat Cucumber Salad" | scion-netcat echoservice.thorben.scionlab:1337
```

### Other Services

There are other services available under their domain names in SCIONLab. For example, try the following:

* `scion-sensorfetcher -s sensorserver.ethz.scionlab:42003`
* `scion-bat HEAD https://netsys.ovgu.de` (this should even work without a working `scion-sdns` deployment, because the `netsys.ovgu.de` domain has a "real" DNS TXT record with its scion address too)

#### Bandwidth Test Servers

There are [Bandwidth Testers](https://docs.scionlab.org/content/apps/bwtester.html) available under the following DNS names:

- `bwtester.frankfurt.aws.scionlab`
- `bwtester.ireland.aws.scionlab`
- `bwtester.virginia.aws.scionlab`
- `bwtester.ohio.aws.scionlab`
- `bwtester.oregon.aws.scionlab`
- `bwtester.singapore.aws.scionlab`
- `bwtester1.ethz.scionlab`
- `bwtester2.ethz.scionlab`
- `bwtester3.ethz.scionlab`
- `bwtester.ap.ethz.scionlab`
- `bwtester1.switch.scionlab`
- `bwtester2.switch.scionlab`
- `bwtester.valencia.eu.scionlab`
- `bwtester.daejeon.korea.scionlab`
- `bwtester.ku.korea.scionlab`

They are all reachable under port 30100. You will need to specify the
parameters for each bandwidth experiment. For demonstration purposes, something like the following might suffice:

```
scion-bwtestclient -s bwtester.frankfurt.aws.scionlab:30100 -cs 1,1000,125,1Mbps -sc 1,1000,125,1Mbps
```

## Troubleshooting

If you get the following error:
```
2022/09/07 16:49:31 host not found: 'echoserver.thorben.scionlab'
```

There are several possible causes:

- You might be using an "old" `scion-netcat` binary that is already
  installed on the host. Check if `dig TXT
  echoserver.thorben.scionlab.` returns a `TXT` record with a `scion`
  entry like in the example above. If that works fine, your
  `scion-netcat` binary does not yet support DNS.
- Your `scion-sdns` version is not running or misconfigured. Check its
  debug output.
- The experimental autoritative name server is offline. Check if it
  can be reached under its address via `scion ping
  "19-ffaa:1:fe4,127.0.0.1"`.

If you get the following error:
```
2022/09/19 16:57:52 no path to 19-ffaa:1:140
```

There are two possibilities:

- The echo server might be offline
- Your scion host has no connection to SCIONLab
