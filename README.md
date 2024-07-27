# Desk OS - A simple, general purpose operating system for desktop computers

## Installation

1. Download the latest [Desk OS installation ISO](https://github.com/nixup-io/desk-os/releases/download/v1.0.0/desk-os-v1.0.0-installer.iso)

2. Flash it to a suitable USB drive

3. Boot it and install it

**Notes**

- The installation ISO assumes you are booting with UEFI and will partition the destination disk with GPT and enable full disk encryption (LUKS).
- After booting into the installed system for the first time and entering the chosen full disk encryption password, you'll be greeted with the login screen. You log in with the user account name you set during installation and the default password is `changeme`.

## Run a Desk OS demo in a virtual machine

This assumes you're running NixOS or another Linux distribution and have the Nix package manager installed.

```sh
nix run github:nixup-io/desk-os
```

## Contact

- E-mail: [info@nixup.io](mailto:info@nixup.io)
- X: [@michaelshmitty](https://x.com/michaelshmitty)
- Fediverse: [@neo](https://social.hacktheplanet.be/@neo)

## Acknowledgements

Desk OS is based on [Linux](https://en.wikipedia.org/wiki/Linux) and [NixOS](https://nixos.org/).
