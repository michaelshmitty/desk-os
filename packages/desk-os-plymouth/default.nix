{stdenv}:
stdenv.mkDerivation {
  pname = "desk-os-plymouth";
  version = "0.0.1";

  src = ./src;

  installPhase = ''
    runHook preInstall
    sed -i 's:\(^ImageDir=\)/usr:\1'"$out"':' desk-os.plymouth
    sed -i 's:\(^ScriptFile=\)/usr:\1'"$out"':' desk-os.plymouth
    mkdir -p $out/share/plymouth/themes/desk-os
    cp * $out/share/plymouth/themes/desk-os
    runHook postInstall
  '';
}
