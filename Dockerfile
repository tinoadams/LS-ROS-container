#####
# Important: must install the same nvidia driver version as the docker host!!! SEE Nvidia install below...
#####
# ROS and Simulation in Docker
# - https://github.com/NVIDIA/nvidia-docker
# - http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration#Using_nvidia-docker
# - https://gernotklingler.com/blog/howto-get-hardware-accelerated-opengl-support-docker/
#
# Container content:
#   1) OS + ROS base install
#   2) Simulation packages
#   3) VSCode user + ROS env setup script
#
# docker run -ti --rm \
#       -e DISPLAY=$DISPLAY \
#       -v /tmp/.X11-unix:/tmp/.X11-unix \
#       --privileged --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
#       --env="DISPLAY=${DISPLAY}" --env='QT_X11_NO_MITSHM=1' --gpus all \
#       CONTAINER_NAME
FROM osrf/ros:noetic-desktop-full-focal

# base install
RUN apt-get update && \
    apt-get install -y software-properties-common python3-vcstool openssh-server sudo ros-$ROS_DISTRO-socketcan-bridge libeigen3-dev libflann-dev libusb-1.0-0 \
        wget git ros-$ROS_DISTRO-cv-bridge ros-$ROS_DISTRO-image-transport ros-$ROS_DISTRO-perception libusb-1.0-0-dev libsystemd-dev python3-pip \
        ros-$ROS_DISTRO-vision-opencv ros-$ROS_DISTRO-image-pipeline ros-$ROS_DISTRO-image-transport-plugins ros-$ROS_DISTRO-perception-pcl ros-$ROS_DISTRO-vision-opencv

# GIT LFS
RUN wget https://github.com/git-lfs/git-lfs/releases/download/v2.7.2/git-lfs-linux-amd64-v2.7.2.tar.gz && \
    tar xzf git-lfs-linux-amd64-v2.7.2.tar.gz && \
    bash ./install.sh && \
    git lfs install && \
    rm -rf git-lfs-linux-amd64-v2.7.2.tar.gz

# FLIR camera drivers
    # nasty hack to get rid of license prompt... i've contacted FLIR for advice
RUN wget https://github.com/tinoadams/LS-ROS-container/releases/download/v1/spinnaker-2.0.0.146-amd64-pkg.tar.gz && \
    tar xzf spinnaker-2.0.0.146-amd64-pkg.tar.gz && \
    cd spinnaker-2.0.0.146-amd64/ && \
    mkdir -p temp1/temp2 && \
    cd temp1 && \
    cp ../libspinnaker_2.0.0.146_amd64.deb ./ && \
    ar x ./libspinnaker_2.0.0.146_amd64.deb && \
    cd temp2 && \
    tar xf ../control.tar.xz && \
    echo '#!/bin/sh' > preinst && \
    sed -i 's/exit 0//g' postinst && \
    tar czf ../control.tar.gz * && \
    cd .. && \
    rm libspinnaker_2.0.0.146_amd64.deb && \
    ar r libspinnaker_2.0.0.146_amd64.deb debian-binary control.tar.gz data.tar.xz && \
    cp libspinnaker_2.0.0.146_amd64.deb ../ && \
    cd .. && \
    dpkg -i libspinnaker_*.deb && \
    dpkg -i libspinnaker-dev_*.deb && \
    dpkg -i libspinnaker-c_*.deb && \
    dpkg -i libspinnaker-c-dev_*.deb && \
    dpkg -i libspinvideo_*.deb && \
    dpkg -i libspinvideo-dev_*.deb && \
    dpkg -i libspinvideo-c_*.deb && \
    dpkg -i libspinvideo-c-dev_*.deb && \
    dpkg -i spinview-qt_*.deb && \
    dpkg -i spinview-qt-dev_*.deb && \
    dpkg -i spinupdate_*.deb && \
    dpkg -i spinupdate-dev_*.deb && \
    dpkg -i spinnaker_*.deb && \
    dpkg -i spinnaker-doc_*.deb && \
    apt-get -f install -y && \
    cd .. && \
    rm -rf spinnaker-2.0.0.146-amd64 spinnaker-2.0.0.146-amd64-pkg.tar.gz

# simulation dependencies
RUN apt-get install -d ros-$ROS_DISTRO-controller-manager-tests && \
    dpkg -i --force-overwrite /var/cache/apt/archives/ros-$ROS_DISTRO-controller-manager-tests_*_amd64.deb
RUN pip3 install paho-mqtt pytz requests PySide2

# ROS Gazebo and simulation nodes
RUN apt-get install -y ros-$ROS_DISTRO-gazebo* ros-$ROS_DISTRO-effort-controllers ros-$ROS_DISTRO-joint-state* ros-$ROS_DISTRO-control*
RUN apt-get install -y python3-tk

# nvidia-container-runtime
ENV NIVIDIA_PACKAGE=nvidia-driver-430
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics
# !!! Must match nvidia driver version on the docker host !!!
RUN add-apt-repository -y ppa:graphics-drivers/ppa && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ${NIVIDIA_PACKAGE}

# Create user for VSCode
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && adduser $USERNAME dialout \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && echo "Set disable_coredump false" >> /etc/sudo.conf
USER $USERNAME

# dev tools
RUN pip3 install pylint autopep8

RUN echo 'alias ll="ls -la"' >> /home/vscode/.bashrc
# VSCode container overrides entrypoint so we load it when the shell starts
RUN echo 'source "/opt/ros/$ROS_DISTRO/setup.bash"' >> /home/vscode/.bashrc
