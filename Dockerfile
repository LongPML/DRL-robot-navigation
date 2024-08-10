ARG OS_NAME=ubuntu
ARG OS_VERSION=18.04

ARG CUDA_VERSION=11.1.1
ARG CUDNN_VERSION=8
ARG CUDA_FLAVOR=runtime    #runtime, devel

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${CUDA_FLAVOR}-${OS_NAME}${OS_VERSION}

# Prevent prompting 
ARG DEBIAN_FRONTEND=noninteractive

# Install languages
RUN apt-get update && apt-get install -y \
    locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8

# Install timezone
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Add user and setup sudo
ARG USERNAME=melodic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Switch user
USER ${USERNAME}
SHELL ["/bin/bash", "-c"]

# Essential packages for python
RUN sudo apt-get update \
    && sudo apt-get install -y \
    build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libreadline-dev libffi-dev wget \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Install python
ARG PYTHON_VERSION=3.6.9
ENV PIP_NO_CACHE_DIR=false

RUN cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar -xvf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && sudo make install \
    && cd .. && rm Python-${PYTHON_VERSION}.tgz && sudo rm -r Python-${PYTHON_VERSION} \
    && sudo ln -s /usr/local/bin/python3 /usr/local/bin/python \
    && sudo ln -s /usr/local/bin/pip3 /usr/local/bin/pip \
    && echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc \
    && source ~/.bashrc \
    && python -m pip install --upgrade pip

# Install torch
ARG PYTORCH_VERSION=1.10.1
ARG TORCHVISION_VERSION=0.11.2
# ARG TORCHAUDIO_VERSION=0.10.1
ARG TORCH_VERSION_SUFFIX=+cu111
ARG PYTORCH_DOWNLOAD_URL=https://download.pytorch.org/whl/torch_stable.html

RUN if [ ! $TORCHAUDIO_VERSION ]; \
    then \
        TORCHAUDIO=; \
    else \
        TORCHAUDIO=torchaudio==${TORCHAUDIO_VERSION}${TORCH_VERSION_SUFFIX}; \
    fi \
    && if [ ! $PYTORCH_DOWNLOAD_URL ]; \
    then \
        sudo pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO}; \
    else \
        sudo pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO} \
            -f ${PYTORCH_DOWNLOAD_URL}; \
    fi

# ROS configure Ubuntu repositories
RUN sudo apt-get update \
    && sudo apt-get install -y software-properties-common \
    && sudo add-apt-repository universe \
    && sudo add-apt-repository restricted \
    && sudo add-apt-repository multiverse \
    && sudo apt-get update \
    && sudo rm -rf /var/lib/apt/lists/*

# Essential packages for ROS
RUN sudo apt-get update && sudo apt-get install -y \
    build-essential curl lsb-release \
    && sudo rm -rf /var/lib/apt/lists/*

# ROS
ARG ROS_DISTRO=melodic
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/ros-latest.list' \
    && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

RUN sudo apt-get update && sudo apt-get install -y --fix-missing \
    ros-${ROS_DISTRO}-desktop-full \
    && sudo rm -rf /var/lib/apt/lists/*

# ROS environment setup
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && source ~/.bashrc

# ROS dependencies for building packages
RUN sudo pip install rosdep rosinstall rosinstall-generator wstool \
    && sudo rosdep init && rosdep update

# RUN sudo apt-get update && sudo apt-get install -y \
#     python-rosdep python-rosinstall python-rosinstall-generator python-wstool \
#     && sudo rm -rf /var/lib/apt/lists/* \
#     && sudo rosdep init && rosdep update

# # Install Gazebo
# ARG GAZEBO_VERION=9
# RUN sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" \
#     > /etc/apt/sources.list.d/gazebo-stable.list' \
#     && wget https://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add - \
#     && sudo apt-get update && sudo apt-get install -y gazebo${GAZEBO_VERION} libgazebo${GAZEBO_VERION}-dev \
#     && sudo rm -rf /var/lib/apt/lists/*

# Fix Symbol lookup error
RUN sudo apt-get update \
    && sudo apt-get upgrade -y libignition-math2

# Requirements and environment
COPY requirements.txt .
RUN sudo pip install -r requirements.txt

# Set up entrypoint
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]

CMD ["bash"]