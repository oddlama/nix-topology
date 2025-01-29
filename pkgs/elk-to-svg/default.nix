{
  buildNpmPackage,
  lib,
}:
buildNpmPackage {
  pname = "elk-to-svg";
  version = "1.0.0";

  src = ./.;
  npmDepsHash = "sha256-EHybxOl+xKXnSFb2TEYqI5ESiIcnSwVWswH4q5pf7F0=";
  dontNpmBuild = true;

  #passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Convert ELK to SVG";
    #homepage = "https://github.com/oddlama/elk-to-svg";
    license = licenses.mit;
    maintainers = with maintainers; [oddlama];
    mainProgram = "elk-to-svg";
  };
}
