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
    concatMap
    filter
    flip
    groupBy
    hasSuffix
    head
    mkOption
    optionalString
    partition
    sort
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

    net = {
      netStylePreview = net: twAttrs: let
        secondaryColor =
          if net.style.secondaryColor == null
          then "#00000000"
          else net.style.secondaryColor;
      in
        {
          solid = ''<div tw="flex flex-none ${twAttrs} bg-[${net.style.primaryColor}]"></div>'';
          dashed = ''<div tw="flex flex-none ${twAttrs}" style="backgroundImage: linear-gradient(90deg, ${net.style.primaryColor} 0%, ${net.style.primaryColor} 50%, ${secondaryColor} 50.01%, ${secondaryColor} 100%);"></div>'';
          dotted = ''<div tw="flex flex-none ${twAttrs}" style="backgroundImage: radial-gradient(circle, ${net.style.primaryColor} 30%, ${secondaryColor} 30.01%);"></div>'';
        }
        .${net.style.pattern};

      mkCard = net: {
        width = 480;
        html =
          mkCardContainer
          /*
          html
          */
          ''
            <div tw="flex flex-row mx-6 mt-2 items-center">
              ${html.net.netStylePreview net "w-12 h-4 mr-4 rounded-md"}
              <h2 tw="text-2xl font-bold">${net.name}</h2>
              <div tw="flex grow min-w-8"></div>
              ${mkImageMaybe "w-12 h-12 ml-4" (config.lib.icons.get net.icon)}
            </div>
            <div tw="flex flex-col mx-6 my-2 grow">
            ${optionalString (net.cidrv4 != null) ''<div tw="flex flex-row"><span tw="text-lg m-0"><b>CIDRv4</b></span><span tw="text-lg text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv4}</span></div>''}
            ${optionalString (net.cidrv6 != null) ''<div tw="flex flex-row"><span tw="text-lg m-0"><b>CIDRv6</b></span><span tw="text-lg text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv6}</span></div>''}
          '';
      };

      mkOverview = {
        width = 480;
        html =
          mkCardContainer
          /*
          html
          */
          ''
            <div tw="flex flex-row mx-6 mt-2 items-center">
              <h2 tw="text-2xl font-bold">Networks Overview</h2>
            </div>

            ${concatLines (flip map (attrValues config.networks) (
              net:
              /*
              html
              */
              ''
                <div tw="flex flex-col mx-4 mt-2 rounded-lg p-2">
                  <div tw="flex flex-row">
                    ${html.net.netStylePreview net "w-12 h-4 mt-2 mr-4 rounded-md"}
                    <div tw="flex flex-col grow">
                      <h1 tw="text-lg font-bold m-0">${net.name}</h1>
                      ${optionalString (net.cidrv4 != null) ''<div tw="flex flex-row"><span tw="text-md text-[#7a899f] m-0"><b>CIDRv4</b></span><span tw="text-md text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv4}</span></div>''}
                      ${optionalString (net.cidrv6 != null) ''<div tw="flex flex-row"><span tw="text-md text-[#7a899f] m-0"><b>CIDRv6</b></span><span tw="text-md text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv6}</span></div>''}
                    </div>
                  </div>
                </div>
              ''
            ))}

            ${spacingMt2}
          '';
      };
    };

    node = rec {
      mkInterface = interface:
      /*
      html
      */
      ''
        <div tw="flex flex-col flex-none items-center border-[#21262e] border-2 rounded-lg px-2 py-1 m-1">
          ${mkImage "w-8 h-8 m-1" (config.lib.icons.get interface.icon)}
          <span tw="font-bold text-xs">${interface.id}</span>
        </div>
      '';

      serviceDetail = detail:
      /*
      html
      */
      ''
        <div tw="flex flex-row flex-wrap mt-1">
          <span tw="flex text-sm flex-none min-w-16 font-bold pl-1">${detail.name}</span>
          <span tw="flex grow"></span>
          <span tw="flex text-sm ml-4">${detail.text}</span>
        </div>
      '';

      serviceDetails = service:
        optionalString (service.details != {}) ''<div tw="flex pt-2"></div>''
        + concatLines ((map serviceDetail) (
          flip sort (attrValues service.details) (
            a: b:
              if a.order != b.order
              then a.order < b.order
              else a.name < b.name
          )
        ));

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
              ${optionalString (service.info != "") ''<p tw="text-sm m-0 pr-6">${service.info}</p>''}
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
            <div tw="flex flex-row mx-6 mt-2 items-center">
              ${mkImageMaybe "w-8 h-8 mr-4" (config.lib.icons.get node.icon)}
              <div tw="flex flex-col min-h-18 justify-center">
                <span tw="text-2xl font-bold">${node.name}</span>
                ${optionalString (node.hardware.info != null) ''<span tw="text-xs">${node.hardware.info}</span>''}
              </div>
              <div tw="flex grow min-w-8"></div>
              ${mkImageMaybe "w-12 h-12 ml-4" (config.lib.icons.get node.deviceIcon)}
            </div>

            ${optionalString (node.interfaces != {}) ''<div tw="flex flex-row flex-wrap items-center my-2 mx-3">''}
            ${concatLines (map mkInterface (attrValues node.interfaces))}
            ${optionalString (node.interfaces != {}) ''</div>''}

            ${concatLines (map mkGuest guests)}
            ${optionalString (guests != []) spacingMt2}

            ${concatLines (map (mkService {}) services)}
            ${optionalString (services != []) spacingMt2}
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
              ${mkImageMaybe "w-8 h-8 mr-4" (config.lib.icons.get node.icon)}
              <div tw="flex flex-col min-h-18 justify-center">
                <span tw="text-2xl font-bold">${node.name}</span>
                ${optionalString (node.hardware.info != null) ''<span tw="text-xs">${node.hardware.info}</span>''}
              </div>
              ${optionalString (deviceIconImage != null && node.hardware.image != null -> deviceIconImage != node.hardware.image)
              ''
                <div tw="flex grow min-w-4"></div>
                ${mkImageMaybe "w-12 h-12" deviceIconImage}
              ''}
            </div>

            <div tw="flex flex-row w-full justify-center">
              ${mkImageMaybe "h-24" node.hardware.image}
            </div>
          '';
      };

      mkPreferredRender = node:
        (
          if node.renderer.preferredType == "image" && node.hardware.image != null
          then mkImageWithName
          else mkCard
        )
        node;
    };

    services.mkOverview = let
      services = concatMap (
        node: let
          visible = filter (x: !x.hidden) (attrValues node.services);
        in
          map (svc: {inherit node svc;}) visible
      ) (attrValues config.nodes);

      # Deduplicate services by serviceId in overview
      deduped = let
        parts = partition (p: p.svc.serviceId != null) services;
        withId = parts.right;
        withoutId = parts.wrong;
        grouped = groupBy (p: p.svc.serviceId) withId;
        uniqueById = map head (attrValues grouped);
      in
        uniqueById ++ withoutId;

      renderService = pair:
        html.node.mkService {
          additionalInfo = ''<p tw="text-sm text-[#7a899f] m-0">${pair.node.name}</p>'';
          includeDetails = false;
        }
        pair.svc;
    in {
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

          ${concatLines (map renderService deduped)}

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

      net.mkCard = net: renderHtmlToSvg (html.net.mkCard net) "card-net-${net.id}";
      net.mkOverview = renderHtmlToSvg html.net.mkOverview "networks-overview";

      node = {
        mkImageWithName = node: renderHtmlToSvg (html.node.mkImageWithName node) "image-with-name-${node.id}";
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
