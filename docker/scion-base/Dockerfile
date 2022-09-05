FROM golang:1.17-alpine
RUN apk add --no-cache bash git build-base bind-tools
WORKDIR /root/go/src
RUN git clone https://github.com/scionproto/scion
RUN cd scion && go build -o ./bin/ ./control/cmd/control && cp ./bin/control /root/control && echo "Built control"
RUN cd scion && go build -o ./bin/ ./daemon/cmd/daemon && cp ./bin/daemon /root/daemon && echo "Built daemon"
RUN cd scion && go build -o ./bin/ ./dispatcher/cmd/dispatcher && cp ./bin/dispatcher /root/dispatcher && echo "Built dispatcher"
RUN cd scion && go build -o ./bin/ ./scion/cmd/scion && cp ./bin/scion /usr/bin/scion && echo "Built scion"
RUN cd scion && go build -o ./bin/ ./scion-pki/cmd/scion-pki && cp ./bin/scion-pki /usr/bin/scion-pki && echo "Built scion-pki"
RUN cd scion && go build -o ./bin/ ./router/cmd/router && cp ./bin/router /root/router && echo "Built router"
RUN git clone https://github.com/netsys-lab/scion-sdns
RUN cd scion-sdns && go build -v . && cp ./sdns /root/scion-sdns && echo "Built scion-sdns"
RUN git clone -b rhine https://github.com/netsys-lab/scion-coredns
RUN cd scion-coredns && go build -v . && cp ./coredns /root/scion-coredns && echo "Built scion-coredns"
RUN git clone https://github.com/netsys-lab/scion-rdig
RUN cd scion-rdig && go build -v . && cp ./rdig /root/scion-rdig && echo "Built scion-rdig"
RUN rm -rf /root/go
