FROM netsys-lab/scion-base
RUN apk add --no-cache bash
COPY run.sh /root/run.sh
RUN chmod +x /root/run.sh
RUN PATH=$PATH:~/root
CMD ["/root/run.sh"]
