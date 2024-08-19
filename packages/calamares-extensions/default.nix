{stdenv}:
stdenv.mkDerivation {
  pname = "calamares-extensions-desk-os";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{lib,share}/calamares
    cp -r modules $out/lib/calamares/
    cp -r config/* $out/share/calamares/
    cp -r branding $out/share/calamares/
    runHook postInstall
  '';
}
