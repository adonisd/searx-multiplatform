# searx-multiplatform
Multi platform build file for Searx
This will fetch the source from searx/searx and build with tag v1.0.0 (If you wish to change that, take a look at the Dockerfile).

Build for amd64:

`docker buildx build -t wristyquill/searx:amd64 .`

Build for amrv7:

`docker buildx build --platform linux/arm/v7 -t wristyquill/searx:armv7 .`

Create cross-platform manifest:

`docker manifest create wristyquill/searx:latest wristyquill/searx:armv7 wristyquill/searx:amd64`

Run:

`docker run -d --name searx -v /home/pi/searx/conf:/etc/searx -v /home/pi/searx/logs:/var/log/uwsgi -p 8080:8080 wristyquill/searx:latest`
