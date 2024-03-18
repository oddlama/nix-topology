{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit
    (lib)
    attrValues
    concatLines
    filter
    hasSuffix
    head
    optionalString
    splitString
    tail
    ;

  getIcon = registry: iconName:
    if iconName == null
    then null
    else config.icons.${registry}.${iconName}.file or null;

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
      <img tw="${twAttrs}" src="data:image/png;base64,${"TODO"}/>"
    ''
    else builtins.throw "Unsupported icon file type: ${file}";

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

  netToD2 = net: ''
    ${net.id}: ${net.name} {
      info: |md
      ${net.cidrv4}
      ${net.cidrv6}
      |
    }
  '';

  nodeInterfaceToD2 = node: interface:
    ''
      ${node.id}.${interface.id}: ${interface.id} {
        info: |md
        ${toString interface.mac}
        ${toString interface.addresses}
        ${toString interface.gateways}
        |
      }
    ''
    + optionalString (interface.network != null) ''
      ${node.id}.${interface.id} -- ${interface.network}
    '';
  # TODO: deduplicate first
  #+ concatLines (flip map interface.physicalConnections (x: ''
  #  ${node.id}.${interface.id} -- ${x.node}.${x.interface}
  #''));

  nodeInterfaceHtmlSpacing = ''
    <div tw="flex mt-2"></div>
  '';
  nodeInterfaceHtml = interface: let
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
          ${mkImage "w-6 h-6 mr-2" (getIcon "interfaces" interface.icon)}
          <span tw="font-bold">${interface.id}</span>
        </div>
        <span>addrs: ${toString interface.addresses}</span>
      </div>
    '';

  nodeServiceDetailsHeader =
    /*
    html
    */
    ''
      <div tw="flex pt-2"></div>
    '';

  nodeServiceDetail = detail:
  /*
  html
  */
  ''
    <div tw="flex flex-row mt-1">
        <span tw="flex flex-none w-20 font-bold pl-1">${detail.name}</span>
        <span tw="flex grow">${detail.text}</span>
    </div>
  '';

  nodeServiceDetails = service:
    optionalString (service.details != {}) nodeServiceDetailsHeader
    # FIXME: order not respected
    + concatLines ((map nodeServiceDetail) (attrValues service.details));

  nodeServiceHtml = service:
  /*
  html
  */
  ''
    <div tw="flex flex-col mx-4 mt-4 bg-[#21262e] rounded-lg p-2">
      <div tw="flex flex-row items-center">
        ${mkImage "w-16 h-16 mr-4 rounded-lg" (getIcon "services" service.icon)}
        <div tw="flex flex-col grow">
          <h1 tw="text-xl font-bold m-0">${service.name}</h1>
          ${optionalString (service.info != "") ''<p tw="text-base m-0">${service.info}</p>''}
        </div>
      </div>
      ${nodeServiceDetails service}
    </div>
  '';

  nodeHtml = node: let
    services = filter (x: !x.hidden) (attrValues node.services);
  in
    /*
    html
    */
    ''
      <div tw="flex flex-col w-full h-full items-center font-mono text-[#e3e6eb]" style="font-family: 'JetBrains Mono'">
        <div tw="flex flex-col w-full h-full bg-[#101419] py-2 rounded-xl">
          <div tw="flex flex-row mx-6 my-2">
            <h2 tw="grow text-4xl font-bold">${node.name}</h2>
            <div tw="flex grow"></div>
            <h2 tw="text-4xl" style="font-family: 'Segoe UI Emoji'">${node.type}</h2>
          </div>

          ${optionalString (node.interfaces != {}) (mkSpacer "Interfaces" + nodeInterfaceHtmlSpacing)}
          ${concatLines (map nodeInterfaceHtml (attrValues node.interfaces))}
          ${optionalString (node.interfaces != {}) nodeInterfaceHtmlSpacing}

          ${optionalString (services != []) (mkSpacer "Services")}
          ${concatLines (map nodeServiceHtml services)}

          <div tw="flex mb-2"></div>
        </div>
      </div>
    '';

  nodeToD2 = node: ''
    ${node.id}: ${node.name} {}

    ${concatLines (map (nodeInterfaceToD2 node) (attrValues node.interfaces))}
  '';

  generateNodeSvg = node: ''
    ${lib.getExe pkgs.html-to-svg} \
      --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
      --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
      --width 680 \
      ${pkgs.writeText "${node.name}.html" (nodeHtml node)} \
      $out/${node.name}.svg
  '';
in
  #pkgs.writeText "network.d2" ''
  #  ${concatLines (map netToD2 (attrValues config.networks))}
  #  ${concatLines (map nodeToD2 (attrValues config.nodes))}
  #''
  pkgs.runCommand "generate-node-svgs" {} ''
    mkdir -p $out
    ${concatLines (map generateNodeSvg (attrValues config.nodes))}
  ''
