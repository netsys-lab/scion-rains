# Manual Test for RAINS Toolset

A user can try out different RAINS components, including RAINS server, publisher, keymanager, and rdig, by manually running them (as command-line tools). This hands-on exercise is good for getting familiar with RAINS and allows tests over arbitrary data.

## Directories

- scripts/

  Scripts to facilitate manual tests. The current all-in-one script `Server_all.sh` 1) generates necessary configuration files, 2) launches authoritative nameservers, 3) publishes zone data to the corresponding nameservers, and 4) runs a recursive resolver.

- keys/

  Delegation keys of zones to sign assertions.
  
  A different key pair (`_pub.pem`, `_sec.pem`) than the default can be generated by `keyManager gen`. Please see the man page for usage.
  
- tls_cert/

  TLS certificates used by RAINS servers to etablish TLS connections.

- config/ 

  Configuration files for RAINS servers (authoritative name servers and resolvers) and publishers as well zone files. This folder and all its files are generated on the fly. To change any testing data, modify corresponding configuration files and run `Server_all.sh` with a third parameter `nogen`.
  
## Run Test

At this moment, RAINS supports two types of transport: TCP and SCION UDP Sockets.

1. Launch servers:

   `./scripts/Server_all.sh scion|tcp SERVER_ADDRESS [nogen]`
   
    Examples:
    
    `./scripts/Server_all.sh tcp 127.0.0.1` (TCP connection)
    
    `./scripts/Server_all.sh scion 17-ffaa:0:1107,[127.0.0.1]` (SCION connection)
    
    `./scripts/Server_all.sh scion 17-ffaa:0:1107,[127.0.0.1] nogen` (do not generate new config files but use existing configuration files in `config/`)
   
2. Send queries:

   `rdig -p 5025 @SERVER_ADDRESS DOMAIN`, SERVER_ADDRESS can be a local or remote host.
   
    Examples:
    
    `rdig -p 5025 @127.0.0.1 www.ethz.ch.`
    
    `rdig -p 5025 @17-ffaa:0:1107,[127.0.0.1] www.ethz.ch.`
    
    `rdig -p 5025 @17-ffaa:0:1107,[127.0.0.1] www.ethz.ch. cert` (querying assertions of type `cert`)
   
     Other queries can be formulated in a similar way. Please refer to the man page of `rdig` for all options.
   