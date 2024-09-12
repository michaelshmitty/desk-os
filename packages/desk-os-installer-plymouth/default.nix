{stdenv}:
stdenv.mkDerivation {
  pname = "desk-os-installer-plymouth";
  version = "0.0.1";

  src = ./src;

  installPhase = ''
    runHook preInstall
    sed -i 's:\(^ImageDir=\)/usr:\1'"$out"':' desk-os-installer.plymouth
    sed -i 's:\(^ScriptFile=\)/usr:\1'"$out"':' desk-os-installer.plymouth
    mkdir -p $out/share/plymouth/themes/desk-os-installer
    cp * $out/share/plymouth/themes/desk-os-installer
    runHook postInstall
  '';
}
