#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
VERSION="${PACKAGE_VERSION:-2.6.0-1}"
ARCH="$(dpkg --print-architecture)"
PACKAGE="ros-noetic-livox-ros-driver"
ROS_PACKAGE="livox_ros_driver"
PREFIX="/opt/ros/${ROS_DISTRO}"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${INSTALL_ROOT}" || -z "${OUTPUT_DIR}" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${PACKAGE}_"*.deb

pkg_root="${BUILD_DIR}/${PACKAGE}"
mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${PACKAGE}"

copy_path() {
  local src="$1"
  if [[ -e "${src}" ]]; then
    mkdir -p "${pkg_root}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${pkg_root}${src#${INSTALL_ROOT}}"
  fi
}

copy_path "${INSTALL_ROOT}${PREFIX}/share/${ROS_PACKAGE}"
copy_path "${INSTALL_ROOT}${PREFIX}/include/${ROS_PACKAGE}"
copy_path "${INSTALL_ROOT}${PREFIX}/lib/${ROS_PACKAGE}"
copy_path "${INSTALL_ROOT}${PREFIX}/share/gennodejs/ros/${ROS_PACKAGE}"
copy_path "${INSTALL_ROOT}${PREFIX}/share/common-lisp/ros/${ROS_PACKAGE}"
copy_path "${INSTALL_ROOT}${PREFIX}/share/roseus/ros/${ROS_PACKAGE}"

if [[ ! -d "${pkg_root}${PREFIX}/share/${ROS_PACKAGE}" ]]; then
  echo "missing installed share directory for ${ROS_PACKAGE}" >&2
  exit 1
fi
if [[ ! -x "${pkg_root}${PREFIX}/lib/${ROS_PACKAGE}/livox_ros_driver_node" ]]; then
  echo "missing installed livox_ros_driver_node" >&2
  exit 1
fi
if [[ ! -f "${pkg_root}${PREFIX}/include/${ROS_PACKAGE}/CustomMsg.h" ]]; then
  echo "missing generated CustomMsg header" >&2
  exit 1
fi

cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: libapr1, ros-noetic-message-runtime, ros-noetic-pcl-ros, ros-noetic-rosbag, ros-noetic-roscpp, ros-noetic-rospy, ros-noetic-sensor-msgs, ros-noetic-std-msgs
Description: Livox ROS1 driver for ROS Noetic
 ROS1 driver node, launch files, configuration, and custom messages for
 first-generation Livox LiDAR devices.
EOF

printf '%s package\n' "${PACKAGE}" > "${pkg_root}/usr/share/doc/${PACKAGE}/README"
find "${pkg_root}" -type d -exec chmod 0755 {} +
find "${pkg_root}" -type f -exec chmod 0644 {} +
chmod 0755 "${pkg_root}/DEBIAN"
chmod 0755 "${pkg_root}${PREFIX}/lib/${ROS_PACKAGE}/livox_ros_driver_node"
fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${PACKAGE}_${VERSION}_${ARCH}.deb" >/dev/null
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "${PACKAGE}_*.deb" -print | sort
