FROM alpine:3.15.4

RUN apk add --no-cache curl

RUN mkdir -p /opt/tikal/

WORKDIR /opt/tikal/

COPY pinger.sh /opt/tikal/pinger.sh

CMD [ "/opt/tikal/pinger.sh" ]
