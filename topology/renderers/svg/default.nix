{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatLines
    concatMap
    concatMapStrings
    filter
    flip
    groupBy
    hasSuffix
    head
    isList
    length
    listToAttrs
    mkOption
    nameValuePair
    optionalString
    sort
    types
    unique
    ;

  # The HTML carries this marker where an icon goes, and the build of the drawing replaces it with
  # the icon's contents. Evaluation then never reads an icon, which would build it, and this
  # works with `allow-import-from-derivation = false`.
  iconMarker =
    file: "@icon-${builtins.substring 0 16 (builtins.hashString "sha256" (toString file))}@";

  # All icons a drawing can show by their marker.
  iconFiles =
    let
      # An icon that doesn't resolve is left out here and throws in the card that shows it, so a
      # bad icon on one entity doesn't stop the drawings of the others.
      get =
        icon:
        let
          result = builtins.tryEval (config.lib.icons.get icon);
        in
        if result.success then result.value else null;
      nodes = attrValues config.nodes;
    in
    listToAttrs (
      map (file: nameValuePair (iconMarker file) file) (
        unique (
          filter (file: file != null) (
            map (net: get net.icon) (attrValues config.networks)
            ++ concatMap (
              node:
              [
                (get node.icon)
                (get node.deviceIcon)
                node.hardware.image
              ]
              ++ map (interface: get interface.icon) (attrValues node.interfaces)
              ++ map (service: get service.icon) (filter (service: !service.hidden) (attrValues node.services))
            ) nodes
          )
        )
      )
    );

  # Writes the text that replaces the marker of an icon into `icon`.
  iconContents =
    file:
    if hasSuffix ".svg" file then
      ''
        ${lib.getExe pkgs.gawk} 'BEGIN { RS = "^$" }
          {
            start = index($0, "<svg ")
            if (!start) { print "no <svg in " FILENAME > "/dev/stderr"; exit 1 }
            rest = substr($0, start + 5)
            next_svg = index(rest, "<svg ")
            if (next_svg) rest = substr(rest, 1, next_svg - 1)
            end = index(rest, "</svg>")
            if (end) rest = substr(rest, 1, end - 1)
            printf "%s", rest
          }' ${file} > icon
      ''
    else
      ''
        ${pkgs.coreutils}/bin/base64 -w0 < ${file} > icon
      '';

  # Replaces the marker of an icon in `card.html`.
  inlineIcon = marker: file: ''
    ${iconContents file}
    ${lib.getExe pkgs.gawk} -v marker=${marker} 'BEGIN { RS = "^$"; getline contents < "icon" }
      {
        rest = $0
        while ((at = index(rest, marker)) > 0) {
          printf "%s%s", substr(rest, 1, at - 1), contents
          rest = substr(rest, at + length(marker))
        }
        printf "%s", rest
      }' card.html > card.html.new
    mv card.html.new card.html
  '';

  htmlToSvgCommand = inFile: outFile: args: ''
    ${lib.getExe pkgs.html-to-svg} \
      --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
      --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
      --width ${toString (args.width or "auto")} \
      --height ${toString (args.height or "auto")} \
      ${inFile} ${outFile}
  '';

  renderHtmlToSvg =
    card: name:
    let
      markers = unique (map head (filter isList (builtins.split "(@icon-[0-9a-f]{16}@)" card.html)));
      out = pkgs.runCommand "${name}.svg" { } ''
        cp ${pkgs.writeText "${name}.html" card.html} card.html
        chmod u+w card.html
        ${concatMapStrings (marker: inlineIcon marker iconFiles.${marker}) markers}
        ${htmlToSvgCommand "card.html" "$out" card}
      '';
    in
    "${out}";

  html = rec {
    mkImage =
      twAttrs: file:
      if file == null then
        ''
          <div tw="flex flex-none bg-[#000000] ${twAttrs}"></div>
        ''
      else if hasSuffix ".svg" file then
        ''<svg tw="${twAttrs}" ${iconMarker file}</svg>''
      else if hasSuffix ".png" file then
        ''<img tw="object-contain ${twAttrs}" src="data:image/png;base64,${iconMarker file}"/>''
      else if hasSuffix ".jpg" file || hasSuffix ".jpeg" file then
        ''<img tw="object-contain ${twAttrs}" src="data:image/jpeg;base64,${iconMarker file}"/>''
      else
        builtins.throw "Unsupported icon file type: ${file}";

    mkImageMaybeIf =
      cond: twAttrs: file:
      optionalString (cond && file != null) (mkImage twAttrs file);
    mkImageMaybe = mkImageMaybeIf true;

    mkSpacer = name: /* html */ ''
      <div tw="flex flex-row w-full items-center">
        <div tw="flex grow h-0.5 my-4 bg-[#242931] border-0"></div>
        <div tw="flex px-4">
          <span tw="text-[#b6beca] font-bold">${name}</span>
        </div>
        <div tw="flex grow h-0.5 my-4 bg-[#242931] border-0"></div>
      </div>
    '';

    mkRootContainer = twAttrs: contents: /* html */ ''
      <div tw="flex flex-col w-full h-full items-center">
      <div tw="flex flex-col w-full h-full text-[#e3e6eb] font-mono ${twAttrs}" style="font-family: 'JetBrains Mono'">
      ${contents}
      </div>
      </div>
    '';

    mkCardContainer = mkRootContainer "bg-[#101419] rounded-xl min-w-[30rem]";

    spacingMt2 = ''
      <div tw="flex mt-2"></div>
    '';

    net = {
      netStylePreview =
        net: twAttrs:
        let
          secondaryColor = if net.style.secondaryColor == null then "#00000000" else net.style.secondaryColor;
        in
        {
          solid = ''<div tw="flex flex-none ${twAttrs} bg-[${net.style.primaryColor}]"></div>'';
          dashed = ''<div tw="flex flex-none ${twAttrs}" style="backgroundImage: linear-gradient(90deg, ${net.style.primaryColor} 0%, ${net.style.primaryColor} 50%, ${secondaryColor} 50.01%, ${secondaryColor} 100%);"></div>'';
          dotted = ''<div tw="flex flex-none ${twAttrs}" style="backgroundImage: radial-gradient(circle, ${net.style.primaryColor} 30%, ${secondaryColor} 30.01%);"></div>'';
        }
        .${net.style.pattern};

      mkCard = net: {
        width = 480;
        html = mkCardContainer /* html */ ''
          <div tw="flex flex-row mx-6 mt-2 items-center">
            ${html.net.netStylePreview net "w-12 h-4 mr-4 rounded-md"}
            <h2 tw="text-2xl font-bold">${net.name}</h2>
            <div tw="flex grow min-w-8"></div>
            ${mkImageMaybe "w-12 h-12 ml-4" (config.lib.icons.get net.icon)}
          </div>
          <div tw="flex flex-col mx-6 my-2 grow">
          ${optionalString (net.cidrv4 != null)
            ''<div tw="flex flex-row"><span tw="text-lg m-0"><b>CIDRv4</b></span><span tw="text-lg text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv4}</span></div>''
          }
          ${optionalString (net.cidrv6 != null)
            ''<div tw="flex flex-row"><span tw="text-lg m-0"><b>CIDRv6</b></span><span tw="text-lg text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv6}</span></div>''
          }
        '';
      };

      mkOverview = {
        html = mkCardContainer /* html */ ''
          <div tw="flex flex-row mx-6 mt-2 items-center">
            <h2 tw="text-2xl font-bold">Networks Overview</h2>
          </div>

          ${concatLines (
            flip map (attrValues config.networks) (net: /* html */ ''
              <div tw="flex flex-col mx-4 mt-2 rounded-lg p-2">
                <div tw="flex flex-row">
                  ${html.net.netStylePreview net "w-12 h-4 mt-2 mr-4 rounded-md"}
                  <div tw="flex flex-col grow">
                    <h1 tw="text-lg font-bold m-0">${net.name}</h1>
                    ${optionalString (net.cidrv4 != null)
                      ''<div tw="flex flex-row"><span tw="text-md text-[#7a899f] m-0"><b>CIDRv4</b></span><span tw="text-md text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv4}</span></div>''
                    }
                    ${optionalString (net.cidrv6 != null)
                      ''<div tw="flex flex-row"><span tw="text-md text-[#7a899f] m-0"><b>CIDRv6</b></span><span tw="text-md text-[${net.style.primaryColor}] m-0 ml-4">${net.cidrv6}</span></div>''
                    }
                  </div>
                </div>
              </div>
            '')
          )}

          ${spacingMt2}
        '';
      };
    };

    node = rec {
      mkInterface = interface: /* html */ ''
        <div tw="flex flex-col flex-none items-center border-[#21262e] border-2 rounded-lg px-2 py-1 m-1">
          ${mkImage "w-8 h-8 m-1" (config.lib.icons.get interface.icon)}
          <span tw="font-bold text-xs">${interface.id}</span>
        </div>
      '';

      serviceDetail = detail: /* html */ ''
        <div tw="flex flex-row flex-wrap mt-1">
          <span tw="flex text-sm flex-none min-w-16 font-bold pl-1">${detail.name}</span>
          <span tw="flex grow"></span>
          <span tw="flex text-sm ml-4">${detail.text}</span>
        </div>
      '';

      serviceDetails =
        service:
        optionalString (service.details != { }) ''<div tw="flex pt-2"></div>''
        + concatLines (
          (map serviceDetail) (
            flip sort (attrValues service.details) (
              a: b: if a.order != b.order then a.order < b.order else a.name < b.name
            )
          )
        );

      mkService =
        {
          additionalInfo ? "",
          includeDetails ? true,
          ...
        }:
        service: /* html */ ''
          <div tw="flex flex-col mx-4 mt-2 rounded-lg p-2">
            <div tw="flex flex-row items-center">
              ${mkImage "w-12 h-12 mr-4" (config.lib.icons.get service.icon)}
              <div tw="flex flex-col grow">
                <h1 tw="text-lg font-bold m-0">${service.name}</h1>
                ${optionalString (service.info != "") ''<p tw="text-sm m-0 pr-6">${service.info}</p>''}
                ${additionalInfo}
              </div>
            </div>
            ${optionalString includeDetails (serviceDetails service)}
          </div>
        '';

      mkGuest = guest: /* html */ ''
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

      mkCard =
        node:
        let
          services = filter (x: !x.hidden) (attrValues node.services);
          guests = filter (x: x.parent == node.id) (attrValues config.nodes);
        in
        {
          width = 480;
          html = mkCardContainer /* html */ ''
            <div tw="flex flex-row mx-6 mt-2 items-center">
              ${mkImageMaybe "w-8 h-8 mr-4" (config.lib.icons.get node.icon)}
              <div tw="flex flex-col min-h-18 justify-center flex-1 min-w-0">
                <span tw="text-2xl font-bold">${node.name}</span>
                ${optionalString (
                  node.hardware.info != null
                ) ''<span tw="text-xs">${node.hardware.info}</span>''}
              </div>
              <div tw="flex min-w-8"></div>
              ${mkImageMaybe "w-12 h-12 ml-4" (config.lib.icons.get node.deviceIcon)}
            </div>

            ${optionalString (
              node.interfaces != { }
            ) ''<div tw="flex flex-row flex-wrap items-center my-2 mx-3">''}
            ${concatLines (map mkInterface (attrValues node.interfaces))}
            ${optionalString (node.interfaces != { }) "</div>"}

            ${concatLines (map mkGuest guests)}
            ${optionalString (guests != [ ]) spacingMt2}

            ${concatLines (map (mkService { }) services)}
            ${optionalString (services != [ ]) spacingMt2}
          '';
        };

      mkImageWithName = node: {
        html =
          let
            deviceIconImage = config.lib.icons.get node.deviceIcon;
          in
          mkRootContainer "items-center" /* html */ ''
            <div tw="flex flex-row mx-6 mt-2 items-center">
              ${mkImageMaybe "w-8 h-8 mr-4" (config.lib.icons.get node.icon)}
              <div tw="flex flex-col min-h-18 justify-center flex-1 min-w-0">
                <span tw="text-2xl font-bold">${node.name}</span>
                ${optionalString (
                  node.hardware.info != null
                ) ''<span tw="text-xs">${node.hardware.info}</span>''}
              </div>
              ${optionalString
                (deviceIconImage != null && node.hardware.image != null -> deviceIconImage != node.hardware.image)
                ''
                  <div tw="flex min-w-4"></div>
                  ${mkImageMaybe "w-12 h-12" deviceIconImage}
                ''
              }
            </div>

            <div tw="flex flex-row w-full justify-center">
              ${mkImageMaybe "h-24" node.hardware.image}
            </div>
          '';
      };

      mkPreferredRender =
        node:
        (
          if node.renderer.preferredType == "image" && node.hardware.image != null then
            mkImageWithName
          else
            mkCard
        )
          node;
    };

    services.mkOverview = {
      html = mkCardContainer /* html */ ''
        <div tw="flex flex-row mx-6 mt-2 items-center">
          <h2 tw="text-2xl font-bold">Services Overview</h2>
        </div>

        ${
          let
            allServices = concatMap (
              node:
              let
                nodeServices = filter (s: !s.hidden) (attrValues node.services);
              in
              map (s: s // { nodeName = node.name; }) nodeServices
            ) (attrValues config.nodes);
            groupedServices = groupBy (s: s.name) allServices;
            sortedNames = sort (a: b: a < b) (lib.attrNames groupedServices);
          in
          concatLines (
            flip map sortedNames (
              name:
              let
                services = groupedServices.${name};
                count = length services;
              in
              if count > 1 then
                let
                  sortedServices = sort (a: b: a.nodeName < b.nodeName) services;
                  mainService = (head services) // {
                    info = "";
                  };
                  rows = flip map sortedServices (s: /* html */ ''
                    <div tw="flex flex-row mt-1">
                       <span tw="text-sm text-[#7a899f]">${s.nodeName}</span>
                       <span tw="flex grow"></span>
                       ${optionalString (
                         s.info != ""
                       ) ''<span tw="text-sm text-[#e3e6eb] text-right pl-4">${s.info}</span>''}
                    </div>
                  '');
                  additionalInfo = concatLines rows;
                in
                flip html.node.mkService mainService {
                  inherit additionalInfo;
                  includeDetails = false;
                }
              else
                let
                  service = head services;
                in
                flip html.node.mkService service {
                  additionalInfo = /* html */ ''<p tw="text-sm text-[#7a899f] m-0">${service.nodeName}</p>'';
                  includeDetails = false;
                }
            )
          )
        }

        ${spacingMt2}
      '';
    };
  };
in
{
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
        mkImageWithName =
          node: renderHtmlToSvg (html.node.mkImageWithName node) "image-with-name-${node.id}";
        mkCard = node: renderHtmlToSvg (html.node.mkCard node) "card-node-${node.id}";
        mkPreferredRender =
          node: renderHtmlToSvg (html.node.mkPreferredRender node) "preferred-render-node-${node.id}";
      };
    };

    renderers.svg.output = pkgs.runCommand "topology-svgs" { } ''
      mkdir -p $out/nodes
      ${concatLines (
        flip map (attrValues config.nodes) (node: ''
          cp ${config.lib.renderers.svg.node.mkPreferredRender node} $out/nodes/${node.id}.svg
        '')
      )}
    '';
  };
}
