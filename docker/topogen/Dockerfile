FROM ubuntu:latest
RUN apt-get update 
RUN apt-get install -y python3 git sudo supervisor iproute2 wget
WORKDIR /home/scion/
RUN useradd scion && chown -R scion /home/scion && mkdir -p /share && usermod -a -G sudo scion && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER scion
RUN git clone https://github.com/martenwallewein/scion 
WORKDIR /home/scion/scion
RUN git checkout feature/docker-compose-topo 
RUN APTARGS=-y ./tools/install_deps
RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz && export PATH=$PATH:/usr/local/go/bin && cd scion-pki/cmd/scion-pki && go build && sudo cp scion-pki /usr/bin/scion-pki
COPY run.sh run.sh
RUN sudo chmod +x run.sh
CMD ["bash", "./run.sh"]