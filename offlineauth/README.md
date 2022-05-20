# RAINS Offline Authentication Protocols

 This is a prototype implementation of the [offline protocols](https://github.com/netsys-lab/scion-rains/tree/master/docs/auth-arch) of RAINS new authentication architecture.


## Dependencies: 

### Libraries:

- Modified Trillian: https://github.com/cyrill-k/trillian
- Modified miekg/dns: https://github.com/robinburkhard/dns

### System Requirements:

- `docker-compose`

## Toy Example (HOWTO)

### Step 1: setup repo and dependencies 

- Clone this repo: `git clone https://github.com/netsys-lab/scion-rains` 
- Clone dependencies: `git clone https://github.com/cyrill-k/trillian` and `git clone https://github.com/robinburkhard/dns`.
- Edit the `go.mod` file in this directory (i.e., `offlineauth/go.mod`) and adjust the respective paths pointing to `trillian` and `dns` to the location where you just cloned them:

```
replace github.com/google/trillian => [path to the just cloned Trillian repo]
replace github.com/miekg/dns => [path to the just cloned miekg/dns repo]
```


### Step 2: setup F-PKI environment 
[fpki-docker](https://github.com/cyrill-k/fpki-docker) is a container cluster for the log server components. Rainsdeleg uses the map-server to receive information on existing certificates and the log-server  to add certificates. 

- `git clone https://github.com/cyrill-k/fpki-docker`

- Append the following lines to the end of `fpki-docker/Go/Dockerfile` 
```
EXPOSE 8090
EXPOSE 8094
```
so that the map-server and log-server can be accessed. (Later the checkerExtension should be a container itself and the log-server should no longer be accessible from the outside. Do not expose 8090)

- `cd `into the `fpki-docker` directory
- Run `docker-compose build`
- Run `docker-compose up`
- Access the container using ``docker exec -i -t experiment bash``
- In the container, run:
```
mkdir data
make createmap
make createtree
make map_initial
```
- Afterwards, you will find the following generated files in the newly created `fpki-docker/config` directory (or under `/mnt/config` inside the container): `logid1 mapid1 logpk1.pem mapk1.pem`

(Further details about log server administration can be found in the `makefile` in the [`cyrill-k/fpki` repo](https://github.com/cyrill-k/fpki))


### Step 3: update and create configs for your F-PKI setup 

- Copy the newly generated `.pem` files to a new directory that you create in the `scion-rains/offlineauth/test/` directory. Suggested name: `sandbox`
- Edit `scion-rains/offlineauth/test/rainsdeleg_test.go` and change the following lines

```go
MAP_PK_PATH     = "testdata/mappk1.pem"
LOG_PK_PATH     = "testdata/logpk1.pem"
MAP_ID          = 3213023363744691885
LOG_ID          = 8493809986858120401
```
to point to the new directory with their key wiles. Also change `MAP_ID` and `LOG_ID` to reflect the contents of the `mapid1` and `logid1` files that were generated in the previous step.

- From within the `offlineauth/test` directory, execute `go test -run TestCreateDemoFiles2` to generate the necessary configs and keys to run a manual toy example.
- Alternatively run `go test -run TestFull` to execute the remaining steps automatically. 

#### Troubleshooting: 
- The fpki-docker container needs to be active. Test configs are set to log-server address `172.18.0.3` and 
map-server address `172.18.0.5`. 


- If the container is up and there is still a Map-Address (or Log-Address) error, use `docker inspect` to check if the servers are running under the correct addresses:
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' map-server` \
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' log-server`

- If there is a mismatch, the addresses can be adjusted by editing `rainsdeleg_test.go`


### Step 4: run toy example with demo files 

Existing example configs can be found in `testing/testdata/configs/`. The general invocation pattern of the binaries for the CA and CheckerExtension is `./ca [ConfigPath]` and `./checker [ConfigPath]`. More information about the components and their config can be found in `ca/README.md` and `checkerExtension/README.md`. Here, we will continue with the toy config that we have previously generated.


- Run `make all` in the`scion-rains/offlineauth` directory to create the binaries in `/build`
- Inspect the contents of the `demo/checker.conf` and `demo/ca.conf` files to see if they reflect your changes to `rainsdeleg_test.go` above.
- Start `../build/ca demo/ca.conf` from within the `scion-rains/offlineauth/test` directory
- From a second tty (e.g., terminal window) start `../build/checker demo/checker.conf` from within the same directory

The Child Zone Manager handles Creating CSRs for NewDlg or ReNewDlg and KeyChangeDlg requests:
`./child NewDlg [KeyType] [PathToPrivateKey] --zone DNSZone`
`./child ReNewDlg [KeyType] [PathToPrivateKey] [PathToCertificate]`

- Generate a key for testing and create NewDlg Request for `ethz.ch` 
```
../build/keyGen Ed25519 demo/ethz.ch.rains.key
../build/child NewDlg Ed25519 demo/ethz.ch.rains.key --zone ethz.ch.rains --out demo
```
- Inspect the generated csr using `openssl req -text -noout -in demo/ethz.ch.rains_Csr.pem`

The Parent Zone Manager handles NewDlg requests for a given CSR \
`./parent [ParentConfigPath] --NewDlg PathToCSR`

- Test parent delegation: `../build/parent demo/ch.conf --NewDlg demo/ethz.ch.rains_Csr.pem`
- Inspect the results:
```
openssl x509 -text -noout -in demo/ch.cert
openssl x509 -text -noout -in demo/ethz.ch.rains_Cert.pem
```


## Notes and Remarks

- Code in `cyrill-k/trustflex` directory is copied from `https://github.com/cyrill-k/fpki`
