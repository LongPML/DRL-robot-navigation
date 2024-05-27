ARG OS_NAME=ubuntu
ARG OS_VERSION=20.04

ARG CUDA_VERSION=11.1.1
ARG CUDNN_VERSION=8
ARG CUDA_FLAVOR=runtime    #runtime, devel

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${CUDA_FLAVOR}-${OS_NAME}${OS_VERSION}

# Prevent prompting 
ARG DEBIAN_FRONTEND=noninteractive

# Install languages
# RUN apt-get update && apt-get install -y \
#     locales \
#     && locale-gen en_US.UTF-8 \
#     && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
#     && rm -rf /var/lib/apt/lists/*
# ENV LANG en_US.UTF-8

# # Install timezone
# RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
#     && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get update \
#     && apt-get install -y tzdata \
#     && dpkg-reconfigure --frontend noninteractive tzdata \
#     && rm -rf /var/lib/apt/lists/*

# Add user and setup sudo
ARG USERNAME=noetic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo\
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Nvida env
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}

# Essential packages
RUN apt-get update && \
    apt-get install -y \
        wget build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev \
        libreadline-dev libffi-dev libsqlite3-dev libbz2-dev liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install python
ARG PYTHON_VERSION=3.8.10

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xvf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make && make install && \
    cd .. && rm Python-${PYTHON_VERSION}.tgz && rm -r Python-${PYTHON_VERSION} && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
    python -m pip install --upgrade pip && \
    rm -r ~/.cache/pip

# Install torch
ARG PYTORCH_VERSION=1.10.0
ARG TORCHVISION_VERSION=0.11.0
# ARG TORCHAUDIO_VERSION=0.10.0
ARG TORCH_VERSION_SUFFIX=+cu111
ARG PYTORCH_DOWNLOAD_URL=https://download.pytorch.org/whl/torch_stable.html

RUN if [ ! $TORCHAUDIO_VERSION ]; \
    then \
        TORCHAUDIO=; \
    else \
        TORCHAUDIO=torchaudio==${TORCHAUDIO_VERSION}${TORCH_VERSION_SUFFIX}; \
    fi && \
    if [ ! $PYTORCH_DOWNLOAD_URL ]; \
    then \
        pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO}; \
    else \
        pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO} \
            -f ${PYTORCH_DOWNLOAD_URL}; \
    fi && \
    rm -r ~/.cache/pip

# FROM nvcr.io/nvidia/pytorch:21.10-py3

# Essential packages for ROS
RUN apt-get update && apt-get install -y \
    build-essential curl lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

RUN apt-get update && apt-get install -y --fix-missing \
    ros-noetic-desktop-full \
    && rm -rf /var/lib/apt/lists/*

# Switch user
USER ${USERNAME}

SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && source ~/.bashrc

RUN pip install empy catkin_pkg rosdep rosinstall rosinstall-generator wstool \
    PyQt5 \
    && sudo rm -r ~/.cache/pip
RUN sudo apt-get update && sudo apt-get install -y python3-rosdep \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo rosdep init && rosdep update

# Requirements and environment
COPY requirements.txt .
RUN pip install -r requirements.txt

ENV ROS_HOSTNAME=localhost
ENV ROS_MASTER_URI=http://localhost:11311
ENV ROS_PORT_SIM=11311
ENV GAZEBO_RESOURCE_PATH=~/DRL-robot-navigation/catkin_ws/src/multi_robot_scenario/launch

# Set up entrypoint
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]

CMD ["bash"]