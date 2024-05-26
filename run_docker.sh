# Display
export XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

docker run -it --rm --privileged --name noetic_desktop_full \
    -v $(pwd):/root/$(basename $(pwd)) -w /root/$(basename $(pwd)) \
    --gpus all \
    --env="DISPLAY=$DISPLAY" --network host\
    --env="QT_X11_NO_MITSHM=1" --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --env="XAUTHORITY=$XAUTH" --volume="$XAUTH:$XAUTH" \
    robot-navigate:latest\
    bash

# VNC (TODO)
# docker run -it --rm --privileged --name noetic_desktop_full \
#     -v $(pwd):/ws -w /ws \
#     --gpus all \
#     --shm-size 1g --network host\
#     --volume ~/.bash_history:/home/vscode/.bash_history \
#     -p 6080:6080 \
#     robot-navigate:latest \
#     bash