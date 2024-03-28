# TODO:
# - disks (from disko) + render
# - hardware info (image small top and image big bottom and full (no card), maybe just image and render position)
# - render router and other devices (card with interfaces, card with just image)
# - render nodes with guests, guests in short form
# - nginx proxy pass render, with upstream support
# - more service info
# - impermanence render?
# - stable pseudorandom colors from palette with no-reuse until necessary
# - search todo and do
# - podman / docker harvesting
# - adjust device icon based on guest type
# - nixos-container extractor
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

  fileBase64 = file: let
    out = pkgs.runCommand "base64" {} ''
      ${pkgs.coreutils}/bin/base64 -w0 < ${file} > $out
    '';
  in "${out}";

  htmlToSvgCommand = inFile: outFile: args: ''
    ${lib.getExe pkgs.html-to-svg} \
      --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
      --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
      --width ${toString (args.width or "auto")} \
      --height ${toString (args.height or "auto")} \
      ${inFile} ${outFile}
  '';

  renderHtmlToSvg = card: name: let
    out = pkgs.runCommand "${name}.svg" {} ''
      ${htmlToSvgCommand (pkgs.writeText "${name}.html" card.html) "$out" card}
    '';
  in "${out}";

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
      then ''<img tw="object-contain ${twAttrs}" src="data:image/png;base64,${builtins.readFile (fileBase64 file)}"/>''
      else if hasSuffix ".jpg" file || hasSuffix ".jpeg" file
      then ''<img tw="object-contain ${twAttrs}" src="data:image/jpeg;base64,${builtins.readFile (fileBase64 file)}"/>''
      else builtins.throw "Unsupported icon file type: ${file}";

    mkImageMaybeIf = cond: twAttrs: file: optionalString (cond && file != null) (mkImage twAttrs file);
    mkImageMaybe = mkImageMaybeIf true;

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

    mkRootContainer = twAttrs: contents:
    /*
    html
    */
    ''
      <div tw="flex flex-col w-full h-full items-center">
      <div tw="flex flex-col w-full h-full text-[#e3e6eb] font-mono ${twAttrs}" style="font-family: 'JetBrains Mono'">
      ${contents}
      </div>
      </div>
    '';

    mkCardContainer = mkRootContainer "bg-[#101419] rounded-xl";

    spacingMt2 = ''
      <div tw="flex mt-2"></div>
    '';

    node = rec {
      mkInterface = interface: let
        color =
          if interface.virtual
          then "#7a899f"
          else "#70a5eb";
      in
        /*
        html
        */
        ''
          <div tw="flex flex-row items-center my-2">
            <div tw="flex flex-row flex-none items-center bg-[${color}] text-[#101419] rounded-lg px-2 py-1 w-46 h-8 mx-4">
              ${mkImage "w-6 h-6 mr-2" (config.lib.icons.get interface.icon)}
              <span tw="font-bold">${interface.id}</span>
            </div>
            <span>${toString interface.addresses}</span>
          </div>
        '';

      serviceDetail = detail:
      /*
      html
      */
      ''
        <div tw="flex flex-row mt-1">
          <span tw="flex text-sm flex-none w-22 font-bold pl-1">${detail.name}</span>
          <span tw="flex text-sm grow">${detail.text}</span>
        </div>
      '';

      serviceDetails = service:
        optionalString (service.details != {}) ''<div tw="flex pt-2"></div>''
        # FIXME: order not respected
        + concatLines ((map serviceDetail) (attrValues service.details));

      mkService = {
        additionalInfo ? "",
        includeDetails ? true,
        ...
      }: service:
      /*
      html
      */
      ''
        <div tw="flex flex-col mx-4 mt-2 rounded-lg p-2">
          <div tw="flex flex-row items-center">
            ${mkImage "w-12 h-12 mr-4 rounded-lg" (config.lib.icons.get service.icon)}
            <div tw="flex flex-col grow">
              <h1 tw="text-lg font-bold m-0">${service.name}</h1>
              ${optionalString (service.info != "") ''<p tw="text-sm m-0">${service.info}</p>''}
              ${additionalInfo}
            </div>
          </div>
          ${optionalString includeDetails (serviceDetails service)}
        </div>
      '';

      mkGuest = guest:
      /*
      html
      */
      ''
        <div tw="flex flex-col mx-4 mt-2 rounded-lg p-2">
          <div tw="flex flex-row items-center">
            ${mkImageMaybe "w-12 h-12 mr-4" (config.lib.icons.get guest.deviceIcon)}
            <div tw="flex flex-col grow">
              <h1 tw="text-lg font-bold m-0">${guest.name}</h1>
              <p tw="text-sm m-0">${guest.guestType}</p>
            </div>
          </div>
        </div>
      '';

      mkTitle = node:
      /*
      html
      */
      ''
        <div tw="flex flex-row mx-6 mt-2 items-center">
          ${mkImageMaybe "w-8 h-8 mr-4" (config.lib.icons.get node.icon)}
          <h2 tw="text-2xl font-bold">${node.name}</h2>
          <div tw="flex grow min-w-8"></div>
          ${mkImageMaybe "w-12 h-12 ml-4" (config.lib.icons.get node.deviceIcon)}
        </div>
      '';

      mkNetCard = node: {
        width = 480;
        html =
          mkCardContainer
          /*
          html
          */
          ''
            ${mkTitle node}

            ${concatLines (map mkInterface (attrValues node.interfaces))}
            ${optionalString (node.interfaces != {}) spacingMt2}

            ${mkImageMaybe "w-full h-24" node.hardware.image}
          '';
      };

      mkCard = node: let
        services = filter (x: !x.hidden) (attrValues node.services);
        guests = filter (x: x.parent == node.id) (attrValues config.nodes);
      in {
        width = 480;
        html =
          mkCardContainer
          /*
          html
          */
          ''
            ${mkTitle node}

            ${concatLines (map mkInterface (attrValues node.interfaces))}
            ${optionalString (node.interfaces != {}) spacingMt2}

            ${concatLines (map mkGuest guests)}
            ${optionalString (guests != []) spacingMt2}

            ${concatLines (map (mkService {}) services)}
            ${optionalString (services != []) spacingMt2}

            ${mkImageMaybe "w-full h-24" node.hardware.image}
          '';
      };

      mkImageWithName = node: {
        html = let
          deviceIconImage = config.lib.icons.get node.deviceIcon;
        in
          mkRootContainer "items-center"
          /*
          html
          */
          ''
            <div tw="flex flex-row mx-6 mt-2 items-center">
              ${mkImageMaybe "w-8 h-8" (config.lib.icons.get node.icon)}
              <h2 tw="text-2xl font-bold">${node.name}</h2>
              ${optionalString (node.hardware.image != null -> deviceIconImage != node.hardware.image)
              ''
                <div tw="flex grow min-w-4"></div>
                ${mkImageMaybe "w-12 h-12" deviceIconImage}
              ''}
            </div>

            ${mkImageMaybe "h-24" node.hardware.image}
          '';
      };

      mkPreferredRender = node:
        (
          if node.preferredRenderType == "image" && node.hardware.image != null
          then mkImageWithName
          else mkCard
        )
        node;
    };

    services.mkOverview = {
      width = 480;
      html =
        mkCardContainer
        /*
        html
        */
        ''
          <div tw="flex flex-row mx-6 mt-2 items-center">
            <h2 tw="text-2xl font-bold">Services Overview</h2>
          </div>

          ${concatLines (flip map (attrValues config.nodes) (
            node: let
              services = filter (x: !x.hidden) (attrValues node.services);
            in
              concatLines (
                flip map services (
                  html.node.mkService {
                    additionalInfo = ''<p tw="text-sm text-[#7a899f] m-0">${node.name}</p>'';
                    includeDetails = false;
                  }
                )
              )
          ))}

          ${spacingMt2}
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
    lib.renderers.svg = {
      services.mkOverview = renderHtmlToSvg html.services.mkOverview "services-overview";

      node = {
        mkNetCard = node: renderHtmlToSvg (html.node.mkNetCard node) "card-network-${node.id}";
        mkCard = node: renderHtmlToSvg (html.node.mkCard node) "card-node-${node.id}";
        mkPreferredRender = node: renderHtmlToSvg (html.node.mkPreferredRender node) "preferred-render-node-${node.id}";
      };
    };

    renderers.svg.output = pkgs.runCommand "topology-svgs" {} ''
      mkdir -p $out/nodes
      ${concatLines (flip map (attrValues config.nodes) (node: ''
        cp ${config.lib.renderers.svg.node.mkPreferredRender node} $out/nodes/${node.id}.svg
      ''))}
    '';
  };
}
