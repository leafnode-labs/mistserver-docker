# mistserver-docker

*Under active development, subject to breaking changes*

Docker image to build and run mistserver with SRT procotol.
Has only been tested on linux systems.

## Build
```
docker build -t leafnode-labs/mistserver .
```

## Run

*Note: Please ensure your shared memory is set to a high value, preferably ~95% of your total available RAM*

Run without mist process
```
docker run --rm --name mistserver --entrypoint=tail leafnode-labs/mistserver -f /dev/null
```

Standard run with:
- default login/password: leafnode/leafnode
- default protocols and srt activated
- 2 srt test streams configured
```
docker run --rm --name mistserver --shm-size=8gb --net=host leafnode-labs/mistserver
   
docker run -d --shm-size=37971m --restart always --name=mistserver \   
--net=host \    
-v <path to config>:/config \   
-v <path to video>:/media \     
leafnode-labs/mistserver 
```

-p 4242 - Web UI
-p 1935 - RTMP
-p 554 - RTSP
-p 8080 - HTTP / HLS
-p 8889 - SRT
-v /etc/localhost:ro


## Publish a live stream

### RTMP
ffmpeg \
-re -f lavfi \
-i testsrc=size=1280x720:rate=30,format=yuv420p \
-f lavfi -i sine -c:v libx264 \r
-b:v 1000k -x264-params \
keyint=60 -c:a aac \
-f flv rtmp://localhost:1935/live/testrtmp

### SRT
ffmpeg \
-re -f lavfi \
-i testsrc=size=1280x720:rate=30,format=yuv420p \
-f lavfi -i sine -c:v libx264 \
-b:v 1000k -x264-params \
keyint=60 -c:a aac \
-f mpegts "srt://localhost:8889?streamid=testsrt"
