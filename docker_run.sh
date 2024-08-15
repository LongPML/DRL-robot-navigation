#!/bin/bash
USERNAME=melodic
XSOCK=/tmp/.X11-unix

xhost +local:$USERNAME

docker run -it \
    --user $USERNAME \
    --name navigate_robot \
    --network host --ipc host \
    -v $(pwd):/home/$USERNAME/$(basename $(pwd)) -w /home/$USERNAME/$(basename $(pwd)) \
    --privileged \
    --env=DISPLAY \
    --volume=$XSOCK:$XSOCK:rw \
    --gpus all --runtime nvidia \
    --env="QT_X11_NO_MITSHM=1" \
    --env="NVIDIA_DRIVER_CAPABILITIES=all" \
    --env="NVIDIA_VISIBLE_DEVICES=all" \
    --device /dev/dri:/dev/dri \
    longpml/navigate-robot:melodic-py3.6.9-torch1.10.1-cu111 \
    bash
