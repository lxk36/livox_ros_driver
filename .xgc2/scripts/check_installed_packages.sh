#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash

rospack find livox_ros_driver >/dev/null
test -x /opt/ros/noetic/lib/livox_ros_driver/livox_ros_driver_node
test -f /opt/ros/noetic/include/livox_ros_driver/CustomMsg.h
test -f /opt/ros/noetic/share/livox_ros_driver/launch/livox_lidar.launch
test -f /opt/ros/noetic/share/livox_ros_driver/config/livox_lidar_config.json

echo "Installed package check passed"
