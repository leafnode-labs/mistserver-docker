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

# Detecting dependencies
WORKDIR /app
RUN for M in /usr/bin/Mist* ; do ldd $M 2>/dev/null | grep -o "/[^[:space:]]*" >> unsorted_dependencies; echo $M >> unsorted_dependencies ; done
RUN ls -1 /usr/local/lib/libsrt* >> unsorted_dependencies
RUN cat unsorted_dependencies | sort -u > dependencies
RUN strip -s /usr/bin/Mist*
RUN strip -s `find /lib | grep \.so$`

FROM debian:stable-slim as mistserver

# Copy shared libraries needed to run mistserver
COPY --from=builder /app/dependencies /app/dependencies
RUN --mount=type=bind,from=builder,source=/,target=/app/rootbuilder while IFS= read -r DEP ; do cp -ar "/app/rootbuilder$DEP" "$DEP" ; done < "/app/dependencies"
RUN ldconfig
#
## Config
WORKDIR /app
RUN mkdir -p config media

# Install ffmpeg to forward stream to broadcaster
RUN apt-get update
RUN apt-get install -y ffmpeg
##
##EXPOSE 4242 8080 1935 554 8889
#
ENTRYPOINT ["MistController"]


#VOLUME /config /media