# searx-multiplatform
Multi platform build file for Searx
This will fetch the source from searx/searx and build with tag v1.0.0 (If you wish to change that, take a look at the Dockerfile).

Using Github actions, the build.sh script will build for the following platforms: 
arm64
amd64
armv7 

Once done it will publish to Docker hub https://hub.docker.com/r/adonisd/searx and to packages on github


To Run:

`docker run -d --name searx -v /home/pi/searx/conf:/etc/searx -v /home/pi/searx/logs:/var/log/uwsgi -p 8080:8080 adonisd/searx:latest`
