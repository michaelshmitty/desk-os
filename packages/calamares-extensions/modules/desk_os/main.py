#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#   SPDX-FileCopyrightText: 2022 Victor Fuentes <vmfuentes64@gmail.com>
#   SPDX-FileCopyrightText: 2019 Adriaan de Groot <groot@kde.org>
#   SPDX-License-Identifier: GPL-3.0-or-later
#
#   Calamares is Free Software: see the License-Identifier above.
#

import os
import re
import secrets
import subprocess

import libcalamares

import gettext
_ = gettext.translation("calamares-python",
                        localedir=libcalamares.utils.gettext_path(),
                        languages=libcalamares.utils.gettext_languages(),
                        fallback=True).gettext

adjectives = [
    "autumn", "hidden", "bitter", "misty", "silent", "empty", "dry", "dark", "summer",
    "icy", "delicate", "quiet", "white", "cool", "spring", "winter", "patient",
    "twilight", "dawn", "crimson", "wispy", "weathered", "blue", "billowing",
    "broken", "cold", "damp", "falling", "frosty", "green", "long", "late", "lingering",
    "bold", "little", "morning", "muddy", "old", "red", "rough", "still", "small",
    "sparkling", "thrumming", "shy", "wandering", "withered", "wild", "black",
    "young", "holy", "solitary", "fragrant", "aged", "snowy", "proud", "floral",
    "restless", "divine", "polished", "ancient", "purple", "lively", "nameless"
]

nouns = [
    "waterfall", "river", "breeze", "moon", "rain", "wind", "sea", "morning",
    "snow", "lake", "sunset", "pine", "shadow", "leaf", "dawn", "glitter", "forest",
    "hill", "cloud", "meadow", "sun", "glade", "bird", "brook", "butterfly",
    "bush", "dew", "dust", "field", "fire", "flower", "firefly", "feather", "grass",
    "haze", "mountain", "night", "pond", "darkness", "snowflake", "silence",
    "sound", "sky", "shape", "surf", "thunder", "violet", "water", "wildflower",
    "wave", "water", "resonance", "sun", "log", "dream", "cherry", "tree", "fog",
    "frost", "voice", "paper", "frog", "smoke", "star"
]

adjective = secrets.choice(adjectives)
noun = secrets.choice(nouns)
number = secrets.randbelow(10_000)

random_hostname = f"{adjective}-{noun}-{number}"

flake = f"""
{{
  description = "deskOS flake";

  inputs = {{
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  }};

  outputs = {{
    self,
    nixpkgs,
  }} @ inputs: {{
    nixosConfigurations.{random_hostname} = nixpkgs.lib.nixosSystem {{
      system = "x86_64-linux";
      specialArgs = {{inherit inputs;}};
      modules = [
        ./configuration.nix
      ];
    }};
  }};
}}
"""

configuration_head = """
{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
"""

configuration_body = """
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.@@username@@ = {
    isNormalUser = true;
    description = "@@fullname@@";
    extraGroups = [ @@groups@@ ];
  };

  programs.firefox.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "@@username@@";
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  nixpkgs.config.allowUnfree = true;
"""

cfghostname = f"""
  networking.hostName = "{random_hostname}";
"""

cfgtime = """
  time.timeZone = "@@timezone@@";
"""

cfglocale = """
  i18n.defaultLocale = "@@LANG@@";
"""

cfglocaleextra = """
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "@@LC_ADDRESS@@";
    LC_IDENTIFICATION = "@@LC_IDENTIFICATION@@";
    LC_MEASUREMENT = "@@LC_MEASUREMENT@@";
    LC_MONETARY = "@@LC_MONETARY@@";
    LC_NAME = "@@LC_NAME@@";
    LC_NUMERIC = "@@LC_NUMERIC@@";
    LC_PAPER = "@@LC_PAPER@@";
    LC_TELEPHONE = "@@LC_TELEPHONE@@";
    LC_TIME = "@@LC_TIME@@";
  };
"""

cfgkeymap = """
  services.xserver.xkb = {
    layout = "@@kblayout@@";
    variant = "@@kbvariant@@";
  };
"""

cfgconsole = """
  console.keyMap = "@@vconsole@@";
"""

configuration_tail = """
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "@@nixosversion@@"; # Did you read the comment?

}
"""

def pretty_name():
    return _("Installing deskOS.")


status = pretty_name()


def pretty_status_message():
    return status


def catenate(d, key, *values):
    """
    Sets @p d[key] to the string-concatenation of @p values
    if none of the values are None.
    This can be used to set keys conditionally based on
    the values being found.
    """
    if [v for v in values if v is None]:
        return

    d[key] = "".join(values)


def run():
    """deskOS Configuration."""

    global status
    status = _("Configuring deskOS")
    libcalamares.job.setprogress(0.1)

    # Create initial config file
    cfg = configuration_head
    gs = libcalamares.globalstorage
    variables = dict()

    # Setup variables
    root_mount_point = gs.value("rootMountPoint")
    configFile = os.path.join(root_mount_point, "etc/nixos/configuration.nix")
    flakeFile = os.path.join(root_mount_point, "etc/nixos/flake.nix")
    flakePath = os.path.join(root_mount_point, "etc/nixos")

    # Pick config parts and prepare substitution

    cfg += configuration_body

    # Setup encrypted swap devices. nixos-generate-config doesn't seem to notice them.
    for part in gs.value("partitions"):
        if part["claimed"] == True and (part["fsName"] == "luks" or part["fsName"] == "luks2") and part["device"] is not None and part["fs"] == "linuxswap":
            cfg += """  boot.initrd.luks.devices."{}".device = "/dev/disk/by-uuid/{}";\n""".format(
                part["luksMapperName"], part["uuid"])

    status = _("Configuring deskOS")
    libcalamares.job.setprogress(0.18)

    cfg += cfghostname

    if (gs.value("locationRegion") is not None and gs.value("locationZone") is not None):
        cfg += cfgtime
        catenate(variables, "timezone", gs.value(
            "locationRegion"), "/", gs.value("locationZone"))

    if (gs.value("localeConf") is not None):
        localeconf = gs.value("localeConf")
        locale = localeconf.pop("LANG").split("/")[0]
        cfg += cfglocale
        catenate(variables, "LANG", locale)
        if (len(set(localeconf.values())) != 1 or list(set(localeconf.values()))[0] != locale):
            cfg += cfglocaleextra
            for conf in localeconf:
                catenate(variables, conf, localeconf.get(conf).split("/")[0])

        cfg += cfgkeymap
        catenate(variables, "kblayout", gs.value("keyboardLayout"))
        catenate(variables, "kbvariant", gs.value("keyboardVariant"))

        if (gs.value("keyboardVConsoleKeymap") is not None):
            try:
                subprocess.check_output(["pkexec", "loadkeys", gs.value(
                    "keyboardVConsoleKeymap").strip()], stderr=subprocess.STDOUT)
                cfg += cfgconsole
                catenate(variables, "vconsole", gs.value(
                    "keyboardVConsoleKeymap").strip())
            except subprocess.CalledProcessError as e:
                libcalamares.utils.error("loadkeys: {}".format(e.output))
                libcalamares.utils.error("Setting vconsole keymap to {} will fail, using default".format(
                    gs.value("keyboardVConsoleKeymap").strip()))
        else:
            kbdmodelmap = open(
                "/run/current-system/sw/share/systemd/kbd-model-map", 'r')
            kbd = kbdmodelmap.readlines()
            out = []
            for line in kbd:
                if line.startswith("#"):
                    continue
                out.append(line.split())
            # Find rows with same layout
            find = []
            for row in out:
                if gs.value("keyboardLayout") == row[1]:
                    find.append(row)
            if find != []:
                vconsole = find[0][0]
            else:
                vconsole = ""
            if gs.value("keyboardVariant") is not None:
                variant = gs.value("keyboardVariant")
            else:
                variant = "-"
            # Find rows with same variant
            for row in find:
                if variant in row[3]:
                    vconsole = row[0]
                    break
                # If none found set to "us"
            if vconsole != "" and vconsole != "us" and vconsole is not None:
                try:
                    subprocess.check_output(
                        ["pkexec", "loadkeys", vconsole], stderr=subprocess.STDOUT)
                    cfg += cfgconsole
                    catenate(variables, "vconsole", vconsole)
                except subprocess.CalledProcessError as e:
                    libcalamares.utils.error("loadkeys: {}".format(e.output))
                    libcalamares.utils.error(
                        "vconsole value: {}".format(vconsole))
                    libcalamares.utils.error("Setting vconsole keymap to {} will fail, using default".format(
                        gs.value("keyboardVConsoleKeymap")))

    if (gs.value("username") is not None):
        fullname = gs.value("fullname")
        groups = ["networkmanager", "wheel"]

        catenate(variables, "username", gs.value("username"))
        catenate(variables, "fullname", fullname)
        catenate(variables, "groups", (" ").join(
            ["\"" + s + "\"" for s in groups]))


    cfg += configuration_tail
    version = ".".join(subprocess.getoutput(
        ["nixos-version"]).split(".")[:2])[:5]
    catenate(variables, "nixosversion", version)

    # Check that all variables are used
    for key in variables.keys():
        pattern = "@@{key}@@".format(key=key)
        if not pattern in cfg:
            libcalamares.utils.warning(
                "Variable '{key}' is not used.".format(key=key))

    # Check that all patterns exist
    variable_pattern = re.compile("@@\w+@@")
    for match in variable_pattern.finditer(cfg):
        variable_name = cfg[match.start()+2:match.end()-2]
        if not variable_name in variables:
            libcalamares.utils.warning(
                "Variable '{key}' is used but not defined.".format(key=variable_name))

    # Do the substitutions
    for key in variables.keys():
        pattern = "@@{key}@@".format(key=key)
        cfg = cfg.replace(pattern, str(variables[key]))

    status = _("Generating deskOS configuration")
    libcalamares.job.setprogress(0.25)

    try:
        # Generate hardware.nix with mounted swap device
        subprocess.check_output(
            ["pkexec", "nixos-generate-config", "--root", root_mount_point], stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        if e.output != None:
            libcalamares.utils.error(e.output.decode("utf8"))
        return (_("nixos-generate-config failed"), _(e.output.decode("utf8")))

    # Write the configuration.nix file
    libcalamares.utils.host_env_process_output(
        ["cp", "/dev/stdin", configFile], None, cfg)

    # Write the flake.nix file
    libcalamares.utils.host_env_process_output(
        ["cp", "/dev/stdin", flakeFile], None, flake)

    status = _("Installing deskOS")
    libcalamares.job.setprogress(0.3)

    # Install
    try:
        output = ""
        proc = subprocess.Popen(["pkexec", "nixos-install", "--no-root-passwd", "--flake", f"{flakePath}#{random_hostname}", "--root", root_mount_point], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        while True:
            line = proc.stdout.readline().decode("utf-8")
            output += line
            libcalamares.utils.debug("nixos-install: {}".format(line.strip()))
            if not line:
                break
        exit = proc.wait()
        if exit != 0:
            return (_("nixos-install failed"), _(output))
    except:
        return (_("nixos-install failed"), _("Installation failed to complete"))

    return None
