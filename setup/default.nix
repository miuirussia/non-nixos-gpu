{
  stdenv,
  non-nixos-gpu-env,
}:

stdenv.mkDerivation {
  name = "non-nixos-gpu";
  src = ./.;
  patchPhase = ''
    substituteInPlace non-nixos-gpu* \
      --replace '@@resources@@' "$out/resources" \
      --replace '@@env@@' "${non-nixos-gpu-env}"
  '';
  installPhase = ''
    mkdir -p $out/{bin,resources}
    cp non-nixos-gpu-setup $out/bin
    cp non-nixos-gpu.service $out/resources
  '';
}
