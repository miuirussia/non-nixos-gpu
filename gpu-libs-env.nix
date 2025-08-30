# SPDX-FileCopyrightText: 2025 Jure Varlec <jure@varlec.si>
#
# SPDX-License-Identifier: MIT

{
  lib,
  buildEnv,
  mesa,
  libvdpau-va-gl,
  intel-media-driver,
  nvidia-vaapi-driver,
  linuxPackages,
  nvidia_x11 ? linuxPackages.nvidia_x11,
  addNvidia ? false,
}:

buildEnv {
  name = "non-nixos-gpu";
  paths = [
    mesa
    libvdpau-va-gl
    intel-media-driver
  ] ++ lib.optionals addNvidia [
    # TODO do it properly with version matching like nixGL
    nvidia_x11
    nvidia-vaapi-driver
  ];
}
