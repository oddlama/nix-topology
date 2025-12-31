{ buildNpmPackage, lib }:
buildNpmPackage {
  pname = "elk-to-svg";
  version = "1.0.0";

  src = ./.;
  npmDepsHash = "sha256-CAzXbGLgsb02A5ehb7XhT6TEYW1XN6s6g5Rr8Blm8kY=";
  dontNpmBuild = true;

  #passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Convert ELK to SVG";
    #homepage = "https://github.com/oddlama/elk-to-svg";
    license = licenses.mit;
    maintainers = with maintainers; [ oddlama ];
    mainProgram = "elk-to-svg";
  };
}
