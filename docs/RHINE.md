# CoreDNS / SDNS / rdig Demo


## Requirements

- Go v1.17 (later versions currently unsupported)
- docker-compose v2.9
- a Linux build environment

## Preparation

Clone this repository with `--recursive` to pull in all necessary submodules. 

## Build the `rdig` binary

* `cd` into the `scion-rdig` submodule
* issue `go build -v`

## Create the necessary local docker images

### Build nameserver docker image

* `cd` into the `scion-coredns` submodule
* issue `make`
* build a local "coredns" docker image: `docker build -t coredns .`

### Build recursive resolver docker image

* `cd` into the `scion-sdns` submodule
* issue `make`
* build a local "sdns" docker image: `docker build -t sdns .`


## Start resolver and nameservers
In the top-level repository directory, `docker-compose up`

It will create a single local network and start three nameservers: 

* `.` (root)
* `com.`
* `rhine-test.com.`

In addition, the `sdns` recursive resolver is also started in a fourth container.

Note: if `docker-compose up` is run without the optional `-d` flag, it will not detach to the background, instead exposing useful log messages from the different services.

## Send query using rdig
Once the services are running successfully, `rdig` can be used to query the resolver, which is listening on port 10003 of localhost.

A demo CA-certificate is provided in `testdata/resolver/certificates/CACert.pem`, which can be passed to `rdig` using the `-cert` flag. End2end validation can be enabled with the `-rhine` flag. A reasonable invocation can therefore look like this:

```
./scion-rdig/rdig -port 10003 -rhine -cert ./testdata/resolver/certificates/CACert.pem @127.0.0.1 www1.rhine-test.com.
```

## Configuration options for additional tests

* Example Zone files for the test nameserves are found in `./testdata/nameserver/zones`

* Corefiles for the plugin used in each zone are found in `./testdata/nameserver`

* More Zones can be supported by adjusting `docker-compose.yml` as needed.

* The resolver configuration is found in `./testdata/resolver/config.yml`

* Additional certificates can be copied to `./testdata/resolver/certificates`

 
