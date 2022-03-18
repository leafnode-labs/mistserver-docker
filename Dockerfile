FROM debian:stable-slim as builder

# install basics
RUN apt-get update
RUN apt-get install -y \
  git \
  tclsh \
  pkg-config \
  cmake \
  libssl-dev \
  build-essential \
  autoconf

# install SRT
WORKDIR /app
RUN git clone https://github.com/Haivision/srt
WORKDIR srt
RUN ls -alh
RUN ./configure
RUN make
RUN make install

# install libsrtp
WORKDIR /app
RUN git clone https://github.com/cisco/libsrtp
WORKDIR libsrtp
RUN ./configure
RUN make
RUN make install

# install mbedtls
WORKDIR /app
RUN git clone -b dtls_srtp_support https://github.com/livepeer/mbedtls
WORKDIR mbedtls
RUN cmake -DENABLE_TESTING=Off .
RUN make
RUN make install

# install mistserver
WORKDIR /app
RUN git clone https://github.com/DDVTECH/mistserver
WORKDIR mistserver
RUN mkdir generated # known bug should be fixed in 3.1
RUN ldconfig # needed to load shared libraries
RUN cmake .
RUN make
RUN make install

FROM debian:stable-slim as mistserver
# Copy shared libraries needed to run mistserver
#COPY --from=builder /usr/local/lib/lib* /usr/local/lib/
#COPY --from=builder /usr/lib/* /usr/lib/
#COPY --from=builder /usr/bin/Mist* /usr/bin/
COPY --from=builder /usr /usr
RUN ldconfig

# Config
WORKDIR /app
RUN mkdir -p config media
COPY server.conf config/
#
#EXPOSE 4242 8080 1935 554 8889

ENTRYPOINT ["MistController",  "-c", "/app/config/server.conf"]

#VOLUME /config /media