<!--
SPDX-FileCopyrightText: 2025 Jure Varlec <jure@varlec.si>

SPDX-License-Identifier: MIT
-->

# GPU setup for Nix programs on non-NixOS systems

When running programs from [nixpkgs][nixpkgs] using [Nix][nix], they will
normally fail to find OpenGL and Vulkan libraries. The reason is that Nix tries
to keep programs "hermetic", keeping track of all dependencies. However, this is
not appropriate for graphics drivers because they depend on the hardware and
must thus be provided by the operating system.

[nix]: https://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs

[NixOS][nix], which is built entirely on Nix, solves this problem in a
particular way. Other distributions do not have the appropriate setup in place.
Consequently, programs run using Nix that depend on OpenGL or Vulkan won't work
out of the box.

This package aims to fix this by providing a NixOS-equivalent setup on other
distributions.


## How does it work?

This package builds a derivation containing OpenGL and Vulkan libraries. It then
installs a Systemd service on the host OS that runs on boot, symlinking these
libraries to `/run/opengl-driver`. This is the location where programs from
nixpkgs expect to find them. Programs from the host OS know nothing about this
directory and are unaffected.


## How is this different from nixGL?

[nixGL][nixgl] is an existing solution that takes a completely different
approach. Instead of mimicking what NixOS does, it injects the needed graphical
libraries by exporting `LD_LIBRARY_PATH` into a program's environment.

This approach works well in many cases. It requries wrapping programs, but that
is a mostly solved problem thanks to wrappers provided with nixGL itself, and
the wrappers provided by [Home Manager][hm].

[nixgl]: https://github.com/nix-community/nixGL
[hm]: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos

However, it often fails in the important case of a wrapped program from nixpkgs
executing a program from the host. For example, Firefox from nixpkgs must be
wrapped by nixGL in order for graphical acceleration to work. If you then
download a PDF file and open it in a PDF viewer that is not installed from
nixpkgs but is provided by the host distribution, there may be issues. Because
Firefox's environment injects libraries from nixGL, they also get injected into
the PDF viewer, and unless they are the same or compatible version as the
libraries on the host, the viewer will not work. This problem manifests more
often with Vulkan because it needs a larger set of injected libraries than
OpenGL.

That said, NixGL has an advantage: it does not require root access to the
machine.


## Usage


### Trying it out

To try this out quickly, just run the following command. Make sure to change the
version of nixpkgs used to the one that matches your system.

``` sh
sudo -i nix --extra-experimental-features "flakes nix-command" \
    build --override-input nixpkgs nixpkgs/nixos-25.05 \
    --out-link /run/opengl-driver github:exzombie/non-nixos-gpu#env
```

That's all. Programs from nixpkgs should now work. To undo this change, all you
need to do is delete `/run/opengl-driver`. **This happens on reboot**, so this
change is temporary.


### A more permanent setup

This flake provides a package called `setup`, which is also the default package
of the flake. It provides a script called `non-nixos-gpu-setup` which creates a
more permanent setup. The quickest way to do so is to run the following command.
Make sure to change the version of nixpkgs used to the one that matches your
system.

``` sh
sudo -i nix --extra-experimental-features "flakes nix-command" \
    run --override-input nixpkgs nixpkgs/nixos-25.05 \
    github:exzombie/non-nixos-gpu
```

Now, the OS setup will be automatically renewed on every boot. This is done by a
systemd service `non-nixos-gpu.service`. If you wish to undo this setup, simply
disable the service and remove it from `/etc/systemd/system`.


## Current status

At the moment, only Free drivers (i.e., mesa) are supported. It should be
possible to support Nvidia drivers as well, but it's more complicated. If you
need Nvidia right now, there's [nixGL][nixgl].
