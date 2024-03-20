{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    attrValues
    concatLines
    filter
    flip
    hasSuffix
    head
    mkOption
    optionalString
    splitString
    tail
    types
    ;

  htmlToSvgCommand = inFile: outFile: ''
    ${lib.getExe pkgs.html-to-svg} \
      --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
      --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
      --width 680 \
      ${inFile} ${outFile}
  '';

  renderHtmlToSvg = html: name: let
    drv = pkgs.runCommand "generate-svg-${name}" {} ''
      mkdir -p $out
      ${htmlToSvgCommand (pkgs.writeText "${name}.html" html) "$out/${name}.svg"}
    '';
  in "${drv}/${name}.svg";

  html = rec {
    mkImage = twAttrs: file:
      if file == null
      then ''
        <div tw="flex flex-none bg-[#000000] ${twAttrs}"></div>
      ''
      else if hasSuffix ".svg" file
      then let
        withoutPrefix = head (tail (splitString "<svg " (builtins.readFile file)));
        content = head (splitString "</svg>" withoutPrefix);
      in ''<svg tw="${twAttrs}" ${content}</svg>''
      else if hasSuffix ".png" file
      # FIXME: TODO png, jpg, ...
      then ''
        <img tw="object-contain ${twAttrs}" src="data:image/png;base64,${"TODO"}/>"
      ''
      else builtins.throw "Unsupported icon file type: ${file}";

    mkImageMaybe = twAttrs: file: optionalString (file != null) (mkImage twAttrs file);

    mkSpacer = name:
    /*
    html
    */
    ''
      <div tw="flex flex-row w-full items-center">
        <div tw="flex grow h-0.5 my-4 bg-[#242931] border-0"></div>
        <div tw="flex px-4">
          <span tw="text-[#b6beca] font-bold">${name}</span>
        </div>
        <div tw="flex grow h-0.5 my-4 bg-[#242931] border-0"></div>
      </div>
    '';

    mkRootContainer = contents:
    /*
    html
    */
    ''
      <div tw="flex flex-col w-full h-full items-center">
      ${contents}
      </div>
    '';

    mkRootCard = twAttrs: contents:
      mkRootContainer
      /*
      html
      */
      ''
        <div tw="flex flex-col w-full h-full bg-[#101419] text-[#e3e6eb] font-mono ${twAttrs}" style="font-family: 'JetBrains Mono'">
        ${contents}
        </div>
      '';

    spacingMt2 = ''
      <div tw="flex mt-2"></div>
    '';

    node = rec {
      mkInterface = interface: let
        color =
          if interface.virtual
          then "#242931"
          else "#70a5eb";
      in
        /*
        html
        */
        ''
          <div tw="flex flex-row items-center my-2">
            <div tw="flex flex-row flex-none bg-[${color}] w-4 h-1"></div>
            <div tw="flex flex-row flex-none items-center bg-[${color}] text-[#101419] rounded-lg px-2 py-1 w-46 h-8 mr-4">
              ${mkImage "w-6 h-6 mr-2" (config.lib.icons.get interface.icon)}
              <span tw="font-bold">${interface.id}</span>
            </div>
            <span>addrs: ${toString interface.addresses}</span>
          </div>
        '';

      serviceDetail = detail:
      /*
      html
      */
      ''
        <div tw="flex flex-row mt-1">
          <span tw="flex flex-none w-20 font-bold pl-1">${detail.name}</span>
          <span tw="flex grow">${detail.text}</span>
        </div>
      '';

      serviceDetails = service:
        optionalString (service.details != {}) ''<div tw="flex pt-2"></div>''
        # FIXME: order not respected
        + concatLines ((map serviceDetail) (attrValues service.details));

      mkService = service:
      /*
      html
      */
      ''
        <div tw="flex flex-col mx-4 mt-4 bg-[#21262e] rounded-lg p-2">
          <div tw="flex flex-row items-center">
            ${mkImage "w-16 h-16 mr-4 rounded-lg" (config.lib.icons.get service.icon)}
            <div tw="flex flex-col grow">
              <h1 tw="text-xl font-bold m-0">${service.name}</h1>
              ${optionalString (service.info != "") ''<p tw="text-base m-0">${service.info}</p>''}
            </div>
          </div>
          ${serviceDetails service}
        </div>
      '';

      mkTitle = node:
      /*
      html
      */
      ''
        <div tw="flex flex-row mx-6 mt-2 items-center">
          ${mkImageMaybe "w-12 h-12 mr-3" (config.lib.icons.get node.icon)}
          <h2 tw="grow text-4xl font-bold">${node.name}</h2>
          <div tw="flex grow"></div>
          <h2 tw="text-4xl">${node.deviceType}</h2>
          ${mkImageMaybe "w-16 h-16 ml-3" (config.lib.icons.get node.deviceIcon)}
        </div>
      '';

      mkInfoCardFull = node: let
        services = filter (x: !x.hidden) (attrValues node.services);
      in
        mkRootCard "rounded-xl"
        /*
        html
        */
        ''
          ${mkTitle node}

          ${optionalString (node.interfaces != {}) (mkSpacer "Interfaces" + spacingMt2)}
          ${concatLines (map mkInterface (attrValues node.interfaces))}
          ${optionalString (node.interfaces != {}) spacingMt2}

          ${optionalString (services != []) (mkSpacer "Services")}
          ${concatLines (map mkService services)}
          ${optionalString (services != []) spacingMt2}

          <div tw="flex mb-2"></div>
        '';
    };
  };
in {
  options.renderers.svg = {
    # FIXME: colors.bg0 = mkColorOption "bg0" "#";

    output = mkOption {
      description = "The derivation containing the rendered output";
      type = types.path;
      readOnly = true;
    };
  };

  config = {
    lib.renderers.svg.node = {
      mkInfoCardFull = node: renderHtmlToSvg (html.node.mkInfoCardFull node) node.name;
    };

    renderers.svg.output = pkgs.runCommand "topology-svgs" {} ''
      mkdir -p $out/nodes
      ${concatLines (flip map (attrValues config.nodes) (
        node:
          htmlToSvgCommand (
            pkgs.writeText "node-${node.name}.html" (html.node.mkInfoCardFull node)
          ) "$out/nodes/${node.name}.svg"
      ))}
    '';
  };
}
