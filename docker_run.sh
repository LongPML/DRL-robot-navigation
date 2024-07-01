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
    --env="DISPLAY=$DISPLAY" --env="QT_X11_NO_MITSHM=1" \
    --volume="$XSOCK:$XSOCK:rw" \
    --env="XAUTHORITY=$XAUTH" --volume="$XAUTH:$XAUTH" \
    navigate-robot:noetic-py3.8.10-torch1.10.0-cu111 \
    bash
