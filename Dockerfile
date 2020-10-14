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
FROM osrf/ros:kinetic-desktop-full-xenial

RUN apt-get update
RUN apt-get install -y  \
        git \
        libeigen3-dev \
        libflann-dev \
        libsystemd-dev \
        libusb-1.0-0 \
        libusb-1.0-0-dev \
        libvtk6-dev \
        libzbar-dev \
        openssh-server \
        python-catkin-tools \
        python-enum34 \
        python-matplotlib \
        python-opencv \
        python-pip \
        python-pip \
        python-pyside \
        python-requests \
        python3-pip \
        python3-venv \
        wget \
        debhelper \
        ros-$ROS_DISTRO-ros-base \
        ros-$ROS_DISTRO-cv-bridge \
        ros-$ROS_DISTRO-hector-gazebo-plugins \
        ros-$ROS_DISTRO-image-pipeline \
        ros-$ROS_DISTRO-image-transport \
        ros-$ROS_DISTRO-image-transport-plugins \
        ros-$ROS_DISTRO-laser-geometry \
        ros-$ROS_DISTRO-lms1xx \
        ros-$ROS_DISTRO-opencv3 \
        ros-$ROS_DISTRO-pcl-ros \
        ros-$ROS_DISTRO-perception \
        ros-$ROS_DISTRO-perception-pcl \
        ros-$ROS_DISTRO-socketcan-bridge \
        ros-$ROS_DISTRO-vision-opencv

# simulation
RUN apt-get install -y  \
    ros-$ROS_DISTRO-control* \
    ros-$ROS_DISTRO-gazebo* \
    ros-$ROS_DISTRO-effort-controllers \
    ros-$ROS_DISTRO-joint-state* \
    python-pyside \
    python-tk

RUN wget https://github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz && \
    tar xvf pcl-1.8.1.tar.gz && \
    cd pcl-pcl-1.8.1 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/local/ .. && \
    make -j8 && \
    make install && \
    cd ../.. && \
    rm -f xvf pcl-1.8.1.tar.gz

RUN pip2 install paho_mqtt requests paho-mqtt pathlib  pyOpenSSL cryptography rfc3339 PyJWT

RUN wget https://github.com/tinoadams/LS-ROS-container/releases/download/v1/spinnaker-1.27.0.48-Ubuntu16.04-amd64-pkg.tar.gz && \
    tar xzf spinnaker-1.27.0.48-Ubuntu16.04-amd64-pkg.tar.gz && \
    cd spinnaker-1.27.0.48-amd64/ && \
    dpkg -i libspinnaker-*.deb && \
    dpkg -i libspinvideo-*.deb && \
    dpkg -i spinview-qt-*.deb && \
    dpkg -i spinupdate-*.deb && \
    dpkg -i spinnaker-*.deb && \
    apt-get -f install -y && \
    cd .. && \
    rm -rf spinnaker-1.27.0.48-amd64 spinnaker-1.27.0.48-Ubuntu16.04-amd64-pkg.tar.gz

RUN wget https://github.com/git-lfs/git-lfs/releases/download/v2.7.2/git-lfs-linux-amd64-v2.7.2.tar.gz && \
    tar xzf git-lfs-linux-amd64-v2.7.2.tar.gz && \
    bash ./install.sh && \
    git lfs install && \
    rm -rf git-lfs-linux-amd64-v2.7.2.tar.gz

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}

ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:graphics-drivers/ppa && apt update

# must be the same nvidia driver version as the docker host!!!
RUN DEBIAN_FRONTEND=noninteractive apt install -y nvidia-430

# Create user for VSCode
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && adduser $USERNAME dialout \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME

RUN pip install --upgrade pip
RUN pip install -U pylint autopep8
RUN sudo pip install vcstool

RUN echo 'alias ll="ls -la"' >> /home/vscode/.bashrc
# VSCode container overrides entrypoint so we load it when the shell starts
RUN echo 'source "/opt/ros/$ROS_DISTRO/setup.bash"' >> /home/vscode/.bashrc
