#!/bin/bash

cd ~/DRL-robot-navigation/catkin_ws

# set up sources:
export ROS_HOSTNAME=localhost
export ROS_MASTER_URI=http://localhost:11311
export ROS_PORT_SIM=11311
export GAZEBO_RESOURCE_PATH=${HOME}/DRL-robot-navigation/catkin_ws/src/multi_robot_scenario/launch
source ~/.bashrc
source devel_isolated/setup.bash

cd ~/DRL-robot-navigation