{
  buildNpmPackage,
  lib,
}:
buildNpmPackage {
  pname = "html-to-svg";
  version = "1.0.0";

  src = ./.;
  npmDepsHash = "sha256-0gm43QSUBg219ueFuNSjz857Y1OttSKFc4VltXF78yg=";
  dontNpmBuild = true;

  #passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Convert satori compatible HTML to SVG";
    #homepage = "https://github.com/oddlama/html-to-svg";
    license = licenses.mit;
    maintainers = with maintainers; [oddlama];
    mainProgram = "html-to-svg";
  };
}
