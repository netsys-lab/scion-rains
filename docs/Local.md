# Executing Test Suite Locally

## Prerequisites

The following instructions have only been tested under Ubuntu 18.04. In addition, at least the following needs to be installed (and configured appropriately)

- docker
- docker-compose

## RAINS Key Generation

### Setting up and starting Google Trillian

From [the official howto](https://github.com/google/trillian/blob/master/examples/deployment/README.md#local-deployments)

> Set a random password and bring up the services defined in the provided compose
file. This includes a local MySQL database, a one-shot container to create the
schema and the trillian server.

```shell
# Set a random password
export MYSQL_ROOT_PASSWORD="$(openssl rand -hex 16)"

# Bring up services defined in this compose file.  This includes:
# - local MySQL database
# - container to initialize the database
# - the trillian server
docker-compose -f examples/deployment/docker-compose.yml up
```

> Verify that your local installation is working by checking the metrics endpoint.

```shell
curl localhost:8091/metrics
```

> Debugging problems with Docker setup is beyond the scope of this document, but
some helpful options include:

 - Showing debug information with the `--verbose` flag.
 - Running `docker events` in a parallel session.
 - Using `docker-compose ps` to show running containers and their ports.
 
### Using the `gen-keys-configs.sh` helper script

Have a look at [gen-keys-configs.sh](https://github.com/netsys-lab/scion-rains/blob/master/scripts/gen-keys-configs.sh). It requires trillian to be up and running.

The `$OUTDIR` variable determines where the generated keys and certificates will be stored. The relevant generated configuration files will be found in `$OUTDIR/configs` and the generated keys will be in `$OUTDIR/data`. 

The `$PARENT` and `$CHILDREN` variables contain the desired TLD and child zone name(s).

The script runs delegation requests for `$CHILDREN` and also creates `Corefile` and `Coresign` files for each instance of [scion-coredns](https://github.com/netsys-lab/scion-coredns) that need to be copied to the respective SCION AS.

Once you have a reasonable understanding of the script and have configured it to your needs, execute it to generate the certificates and key material.

## Local SCION Setup

The local test environment will run locally using docker compose.

### Build the necessary containers

Execute [build-containers.sh](https://github.com/netsys-lab/scion-rains/blob/master/scripts/build-containers.sh). It will build a range of necessary components.

### Generate the experimental topology

Once the containers are built, create a directory for the files that will be generated in the next step:

- `mkdir generated`

Then generate the necessary files using the provided example topology (under `testdata/local/sample.topo`):

- `docker run -v ./testdata/local/sample.topo:/share/topology.json -v generated:/share/output netsys-lab/topogen`

(Also see [this readme](https://github.com/netsys-lab/scion-docker-compose/blob/master/Readme.md))

The `generated` directory should now be populated with configuration files and subdirectories for each of the simulated SCION ASes. (Also see [the official SCION documentation](https://scion.docs.anapaya.net/en/latest/build/setup.html).)

As a precaution, we will remove the default `docker-compose.yml` file that was also generated, because we will need to use a more sophisticated version that is part of the RAINS distribution instead:

- `rm generated/docker-compose.yml`

## Complete the local deployment

The generated local SCION topology and the generated RAINS config now need to be merged and additional config files deployed.

### Deploying RAINS keys and configs

The generated key material and zone configuration files now need to be added to the `generated` directory. 
The generated `ROOT_cert.pem` certificate and the `sdns.yml` file for `scion-sdns` needs to be put into the `generated` directory. An example for the latter is provided under `testdata/local`. The `rootscionservers` variable might need adjustment and `cacertificatefile` needs to point to `ROOT_cert.pem`. 

Fron the different zone subdirectories in the `$OUTDIR` directory above, copy the respective `Coresign` and `Corefile` files as well as associated keys into the `ASff00_0_XXX` subdirectories.

### Creating and signing the zones

For each AS in the `generated` directory, you will also need to configure a zone. Sample configurations are provided under `testdata/local/`, but may need to be adapted.

Sign each zone using the `Coresign` file and the following script (from within the `generated/` directory).

`for I in ASff00_0_11*; do pushd $I; /path/to/scion-coredns -conf Coresign & PID=$!; sleep 3; kill $PID; popd; done`


### Docker Compose

The RAINS distribution comes with its own [`docker-compose.yml`](https://github.com/netsys-lab/scion-rains/blob/master/testdata/local/docker-compose.yml), that corresponds to the provided [`sample.topo`] topology configuration:

- `cp testdata/local/docker-compose.yml generated/docker-compose.yml`

**NB: You will need to manually edit `docker-compose.yml` if you decide to make changes to `sample.topo`. In this case, carefully compare the contents of the `docker-compose.yml` file that was generated by default with the [customized one](https://github.com/netsys-lab/scion-rains/blob/master/testdata/local/docker-compose.yml) that is part of this distribution and comprehend the differences.**


## Start the local deployment

It is recommended to start `docker-compose` in the foreground, i.e., without the `-d` flag to keep an eye on the debug output:
    
- `docker-compose -f generated/docker-compose.yml`

### Test name Resolution

If key generation, deployment configuration and zone signing worked as intended and no changes were made to `sample.topo` nor the provided `docker-compose.yml`, the following command can be used to verify that every virtual AS as a working resolver and can perform recursive lookups


- `for I in `seq 10 15`; do docker exec -ti $(docker ps | grep daemon | grep -E "1$I-1$" | cut -d' ' -f 1) /bin/bash -c 'dig TXT resolver.thirteen.scion.'; done`
