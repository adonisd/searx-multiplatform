# searx-multiplatform
Multi platform build file for Searx

Build for amd64:
`docker buildx build -t wristyquill/searx:amd64 .`

Build for amrv7:
`docker buildx build --platform linux/arm/v7 -t wristyquill/searx:armv7 .`

Create cross-platform manifest:
`docker manifest create wristyquill/searx:latest wristyquill/searx:armv7 wristyquill/searx:amd64`

Run:
`docker run -d --name searx -v /home/pi/searx/conf:/etc/searx -v /home/pi/searx/logs:/var/log/uwsgi -p 8080:8080 wristyquill/searx:latest`
