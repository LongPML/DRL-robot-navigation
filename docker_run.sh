#!/bin/bash
USERNAME=noetic
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

docker run -it \
    --user $USERNAME \
    --name navigate_robot \
    --network host --ipc host \
    -v $(pwd):/home/$USERNAME/$(basename $(pwd)) -w /home/$USERNAME/$(basename $(pwd)) \
    --privileged \
    --gpus all \
    --volume=$XSOCK:$XSOCK:rw \
    --volume=$XAUTH:$XAUTH:rw \
    --env="XAUTHORITY=${XAUTH}" \
    --env="DISPLAY" \
    navigate-robot:noetic-py3.8.10-torch1.10.0-cu111 \
    bash
