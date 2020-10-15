# LS-ROS-container

The container includes all ROS, Gazebo and compiler (C++/Python) components required.

In order to run the 3D graphics environment within a Docker container,
you will need to install docker and nvidia-docker2 on your machine.

- https://github.com/NVIDIA/nvidia-docker

General info about ROS in Docker

- http://moore-mike.com/docker-ros.html

GUI apps in containers

- The short story: https://blog.jessfraz.com/post/docker-containers-on-the-desktop/
- The long story: https://github.com/mviereck/x11docker

Known limitations
---

- Only works on Linux hosts
- NVidia driver version must match the hosts NVidia driver version (at least roughly)
- User on host must have be ID `1000` ie. check by running the following on your shell: ``[ $UID == 1000 ] && echo "Good" || echo "Bad"``

Docker hub
---

Pre-built container versions available here:

https://hub.docker.com/r/tadams/ls-ros-container

Docker tags
---

Containers are named according to the project name `ls-ros-container` and tagged based on the
git branch name and git hash.

The `Makefile` targets will automatically name containers using this scheme:

`ls-ros-container:noetic-dev-env-nvidia-430-0dda930`.
- Project `ls-ros-container`
- Branch `noetic-dev-env-nvidia-430`
- Commit hash `0dda930`

Build, test/run and publish
---

To list all available make targets run `make`.

Usual workflow:

```
make build
make run
make deploy
```
