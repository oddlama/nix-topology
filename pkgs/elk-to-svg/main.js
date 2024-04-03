import fs from "node:fs/promises";
import syncFs from 'node:fs';
import { Command } from "commander";
import ELK from "elkjs/lib/elk.bundled.js";
import { optimize } from 'svgo';
import { parse as parseSvg } from 'svg-parser';

const defaultStyles = {
    background: "#080a0d",
    nodeShapeStroke: "#444488",
    nodeShapeFill: "#ddddff",
    labelStroke: "none",
    labelFill: "#b6beca",
    labelFontFamily: "JetBrains Mono",
    labelFontSize: "12px",
    edgeStrokeWidth: 2,
    edgeStroke: "#b6beca",
    edgeFill: "none",
    portShapeFill: "#6666cc",
    portShapeStroke: "#444488",
    portShapeStrokeWidth: 2,
};

function svg(strings, ...values) {
    let str = '';
    strings.forEach((s, i) => {
        str += s + (values[i] || '');
    });
    return str;
}

function createSvgPath(data, radius) {
    const {
        startPoint,
        endPoint
    } = data;
    const bendPoints = data.bendPoints || [];
    let path = `M ${startPoint.x} ${startPoint.y}`;

    let lx = startPoint.x;
    let ly = startPoint.y;

    for (let i = 0; i < bendPoints.length; i++) {
        const bx = bendPoints[i].x;
        const by = bendPoints[i].y;

        if (bendPoints[i].shared == true) {
            path += ` L ${bx} ${by}`;
        } else {
            const next = bendPoints[i + 1] || endPoint;
            const nx = next.x;
            const ny = next.y;

            // Calculate the lengths of the line segments
            const d1 = Math.sqrt((bx - lx) ** 2 + (by - ly) ** 2);
            const d2 = Math.sqrt((nx - bx) ** 2 + (ny - by) ** 2);

            // Adjust the maximum radius based on the shortest half-line segment
            const maxRadius = Math.min(d1, d2) / 2;
            const adjustedRadius = Math.min(radius, maxRadius);

            // Calculate intersection points
            const ix = bx + ((lx - bx) / d1) * adjustedRadius;
            const iy = by + ((ly - by) / d1) * adjustedRadius;

            const jx = bx + ((nx - bx) / d2) * adjustedRadius;
            const jy = by + ((ny - by) / d2) * adjustedRadius;

            // Calculate the cross product
            const crossProduct = (jx - bx) * (iy - by) - (jy - by) * (ix - bx);

            // Append path segment with the correct turn flag
            path += ` L ${ix} ${iy} A ${adjustedRadius} ${adjustedRadius} 0 0 ${crossProduct >= 0 ? 1 : 0} ${jx} ${jy}`;
        }

        lx = bx;
        ly = by;
    }

    path += ` L ${endPoint.x} ${endPoint.y}`;

    return path;
}

function isPointOnSegment(A, B, P, radius) {
    // Project P onto A->B
    let dX_AB = B.x - A.x;
    let dY_AB = B.y - A.y;
    let dX_AP = P.x - A.x;
    let dY_AP = P.y - A.y;
    // dot product of (B - A) and (P - A)
    let dotProduct = dX_AB * dX_AP + dY_AB * dY_AP;
    let length_AB = Math.sqrt(dX_AB * dX_AB + dY_AB * dY_AB);
    let projDistance = dotProduct / length_AB;

    // If projected point isn't in the inner segment (including the radius),
    // then we can already return
    if (projDistance <= radius || projDistance >= length_AB - radius) {
        return false;
    }

    // Check whether real point P is at least epsilon-near to P',
    // calculate distance of P to line
    let dX_PA = A.x - P.x;
    let dY_PA = A.y - P.y;
    let distance = Math.abs(dX_AB * dY_PA - dX_PA * dY_AB) / length_AB;
    return distance < 0.01;
}

function toSvgPaths(edge) {
    const radius = 5.0;
    //const lines = [];

    //// Assuming `sections` is your array of objects
    //edge.sections.forEach(section => {
    //  const segmentPoints = [section.startPoint, ...(section.bendPoints || []), section.endPoint];
    //  // Create lines for each adjacent pair of points
    //  for (let i = 0; i < segmentPoints.length - 1; i++) {
    //    lines.push([segmentPoints[i], segmentPoints[i + 1]]);
    //  }
    //});

    //edge.sections.forEach(section => {
    //  if (section.bendPoints) {
    //    section.bendPoints.forEach(bendPoint => {
    //      bendPoint.shared = false; // Initialize shared property
    //      for (const line of lines) {
    //        if (isPointOnSegment(line[0], line[1], bendPoint, radius)) {
    //          bendPoint.shared = true;
    //          break; // No need to check further lines once shared is set to true
    //        }
    //      }
    //    });
    //  }
    //});

    return (edge.sections || []).map(section => {
        return createSvgPath(section, radius)
    })
}

function objectToString(obj) {
    return Object.entries(obj)
        .map(([key, value]) => `${key}="${value}"`)
        .join(' ');
}

function renderGraph(g, options, scaleFactor = 1.0) {
    // marker-end="url(#edgeShapeMarker)"
    const edgeShape = (edge_d, edge_path) => {
		let style = Object.assign({}, edge_d.style);
		var bg = "";
		let styleBg = {};
		styleBg["fill"] = style["fill"]
		styleBg["stroke-width"] = style["stroke-width"];
        if (style["background"]) {
			styleBg["stroke"] = style["background"];
			delete style["background"];
			bg = svg`
				<path d="${edge_path}" ${objectToString(styleBg)} />
			`;
        }
		return svg`
			${bg}
			<path d="${edge_path}" ${objectToString(style)} />
		`;
	};

    const edge = edge_d => {
        if (!edge_d.style) {
            edge_d.style = {};
        }
        if (!edge_d.style["fill"]) {
            edge_d.style["fill"] = defaultStyles.edgeFill;
        }
        if (!edge_d.style["stroke"]) {
            edge_d.style["stroke"] = defaultStyles.edgeStroke;
        }
        if (!edge_d.style["stroke-width"]) {
            edge_d.style["stroke-width"] = defaultStyles.edgeStrokeWidth;
        }
        return svg`
        <g>${toSvgPaths(edge_d).map(edge_path => edgeShape(edge_d, edge_path)).join(" ")}</g>
        `
    };

    const nodeShape = node_d => {
        if (node_d.svg) {
			// Load svg
			var content = syncFs.readFileSync(node_d.svg.file, {
				encoding: "utf8"
			});
			// strip <svg> tag, only take the inner stuff (chromium is too dumb for it)
			content = content.substring(content.indexOf('>')+1)
			content = content.substring(0, content.indexOf('</svg>'))
			// replace mask names to be globally unique
			content = content.replaceAll("satori", Buffer.from(node_d.id).toString('base64url'))

            return svg`
                <g transform="translate(${node_d.x.toString()} ${node_d.y.toString()})">
                    <g transform="scale(${node_d.svg.scale} ${node_d.svg.scale})">
						${content}
                    </g>
                </g>
            `;
        }
        if (!node_d.style) {
            node_d.style = {};
        }
        if (!node_d.style["fill"]) {
            node_d.style["fill"] = defaultStyles.nodeShapeFill;
        }
        if (!node_d.style["stroke"]) {
            node_d.style["stroke"] = defaultStyles.nodeShapeStroke;
        }
        return svg`
            <rect
                x="${node_d.x.toString()}"
                y="${node_d.y.toString()}"
                width="${node_d.width.toString()}"
                height="${node_d.height.toString()}"
                ${objectToString(node_d.style)}
            />
        `;
    };
    const nodeLabel = (node_d, label_d) => {
        if (!label_d.style) {
            label_d.style = {};
        }
        if (!label_d.style["stroke"]) {
            label_d.style["stroke"] = defaultStyles.labelStroke;
        }
        if (!label_d.style["fill"]) {
            label_d.style["fill"] = defaultStyles.labelFill;
        }
        if (!label_d.style["style"]) {
            label_d.style["style"] = `font: ${defaultStyles.labelFontSize} ${defaultStyles.labelFontFamily};`;
        }
        if (!label_d.style["text-anchor"]) {
            label_d.style["text-anchor"] = "left";
        }
        if (!label_d.style["dominant-baseline"]) {
            label_d.style["dominant-baseline"] = "hanging";
        }
		return svg`
			<text
			x="${node_d.x + label_d.x}"
			y="${node_d.y + label_d.y}"
			${objectToString(label_d.style)}>${label_d.text}</text>
		`
	};

    const nodePortLabel = (node_d, port_d, label_d) => {
        if (!label_d.style) {
            label_d.style = {};
        }
        if (!label_d.style["stroke"]) {
            label_d.style["stroke"] = defaultStyles.labelStroke;
        }
        if (!label_d.style["fill"]) {
            label_d.style["fill"] = defaultStyles.labelFill;
        }
        if (!label_d.style["style"]) {
            label_d.style["style"] = `font: ${defaultStyles.labelFontSize} ${defaultStyles.labelFontFamily};`;
        }
        if (!label_d.style["text-anchor"]) {
            label_d.style["text-anchor"] = "left";
        }
        if (!label_d.style["dominant-baseline"]) {
            label_d.style["dominant-baseline"] = "hanging";
        }
		return svg`
			<text
			x="${node_d.x + port_d.x + label_d.x}"
			y="${node_d.y + port_d.y + label_d.y}"
			${objectToString(label_d.style)}>${label_d.text}</text>
		`
	}

    const nodePort = (node_d, port_d) => {
        if (!port_d.style) {
            port_d.style = {};
        }
        if (!port_d.style["fill"]) {
            port_d.style["fill"] = defaultStyles.portShapeFill;
        }
        if (!port_d.style["stroke"]) {
            port_d.style["stroke"] = defaultStyles.portShapeStroke;
        }
        if (!port_d.style["stroke-width"]) {
            port_d.style["stroke-width"] = defaultStyles.portShapeStrokeWidth;
        }
		return svg`
    <rect
      x="${node_d.x + port_d.x}"
      y="${node_d.y + port_d.y}"
      width="${port_d.width}"
      height="${port_d.height}"
      ${objectToString(port_d.style)}
    />
    ${port_d.labels && port_d.labels.map(label_d => nodePortLabel(node_d, port_d, label_d)).join(" ")}
  `}
    const node = (node_d, parent_d) => svg`
    <g transform="translate(${parent_d.x.toString()} ${parent_d.y.toString()})">
      <g>${nodeShape(node_d)}</g>
      <g>${node_d.labels && node_d.labels.map(label_d => nodeLabel(node_d, label_d)).join(" ")}</g>
      <g>${node_d.ports && node_d.ports.map(port_d => nodePort(node_d, port_d)).join(" ")}</g>
      <g>${node_d.children && node_d.children.map(_node_d => node(_node_d, node_d)).join(" ")}</g>
      <g transform="translate(${node_d.x.toString()} ${node_d.y.toString()})">
        ${node_d.edges && node_d.edges.map(edge_d => edge(edge_d)).join(" ")}
      </g>
    </g>
  `
    const diagram = svg`
    <svg xmlns="http://www.w3.org/2000/svg"
      viewBox="${g.x.toString()} ${g.y.toString()} ${g.width} ${g.height}"
      width="${g.width * scaleFactor}"
      height="${g.height * scaleFactor}">
      <style>
      @font-face {
        font-family: 'JetBrains Mono';
        font-style: normal;
        font-weight: 400;
		src: url(data:font/truetype;base64,${syncFs.readFileSync(options.font).toString("base64")}) format('truetype');
      }
      @font-face {
        font-family: 'JetBrains Mono';
        font-style: normal;
        font-weight: 700;
		src: url(data:font/truetype;base64,${syncFs.readFileSync(options.fontBold).toString("base64")}) format('truetype');
      }
      </style>
      <defs>
        <marker
          id="edgeShapeMarker"
          markerWidth="10"
          markerHeight="10"
          refX="6"
          refY="3"
          orient="auto"
          markerUnits="strokeWidth">
          <path
            d="M0,0 L0,6 L6,3 z"
            fill="${defaultStyles.edgeStroke}"
          />
        </marker>
      </defs>
      <rect width="${g.width.toString()}" height="${g.height.toString()}" fill="${defaultStyles.background}"/>
      <g>${g.children.map(node_d => node(node_d, g)).join(" ")}</g>
      <g>${g.edges && g.edges.map(edge_d => edge(edge_d)).join(" ")}</g>
    </svg>
   `

    return diagram;
}

function mergeEdges(edges) {
  const mergedEdges = [];

  function cleanEdge(obj) {
	const newObj = Object.assign({}, obj);
    delete newObj["id"];
    delete newObj["sources"];
    delete newObj["targets"];
    return newObj;
  }

  // Helper function to check if two arrays have common elements
  function haveCommonElements(arr1, arr2) {
    return arr1.some(item => arr2.includes(item));
  }

  // Iterate through each edge
  edges.forEach(edge => {
    let merged = false;

    // Check if this edge shares sources or targets with any existing merged edge
	mergedEdges.forEach(mergedEdge => {
      if (
        JSON.stringify(cleanEdge(edge)) === JSON.stringify(cleanEdge(mergedEdge)) &&
        (haveCommonElements(edge.sources, mergedEdge.sources) ||
          haveCommonElements(edge.targets, mergedEdge.targets))
      ) {
		// Merge sources and targets
        mergedEdge.sources = [...new Set([...edge.sources, ...mergedEdge.sources])];
        mergedEdge.targets = [...new Set([...edge.targets, ...mergedEdge.targets])];
        merged = true;
        return;
      }
    });

	// If no merge occurred, add the edge as is
    if (!merged) {
	  mergedEdges.push({ ...edge });
    }
  });

  return mergedEdges;
}

const program = new Command();

program
    .name("elk-to-svg")
    .description("Convert ELK to SVG")
    .version("1.0.0")
    .argument("<input>", "ELK json graph")
    .argument("<output>", "output svg")
	.option("--font <font>", "Sets the font")
	.option("--font-bold <font>", "Sets the bold font")
    .action(async (input, output, options) => {
        const elk = new ELK()
        const graph = JSON.parse(await fs.readFile(input, {
            encoding: "utf8"
        }));

        const preprocessNode = node => {
            if (node.svg) {
                // Load svg
                let content = syncFs.readFileSync(node.svg.file, {
                    encoding: "utf8"
                });

                // Fill in width and height based on node images
                let svgContent = parseSvg(content).children.find((x, _1, _2) => x.tagName == "svg" && x.type == "element");
                let viewBox = svgContent.properties.viewBox.split(" ").map(x => parseInt(x, 10))

                node.svg.width = svgContent.properties.width || (viewBox[2] - viewBox[0]);
                node.svg.height = svgContent.properties.height || (viewBox[3] - viewBox[1]);

                if (!node.width || node.width == 0) {
                    node.width = node.svg.width;
                }
                if (!node.height || node.height == 0) {
                    node.height = node.svg.height;
                }

                if (node.svg.scale) {
                    node.width = node.width * node.svg.scale;
                    node.height = node.height * node.svg.scale;
                } else {
                    node.svg.scale = 1.0;
                }

                if (!node.properties) {
                    node.properties = {};
                }
                node.properties["nodeSize.minimum"] = `(${node.width},${node.height})`;
                node.properties["nodeSize.constraints"] = "[MINIMUM_SIZE]";
            }

            if (node.children) {
                node.children.forEach(preprocessNode);
            }
        };

        graph.children.forEach(preprocessNode);
		//var mergedEdges = mergeEdges(graph.edges);

        //console.log(JSON.stringify(graph));
        const layoutedGraph = await elk.layout(graph).catch(function(e) {
            console.error(e)
            process.exit(1);
        });

		// Move edges to the node containing them, so we can render them with the correct offset later
		const acquireEdges = node => {
			if (!node.edges) {
				node.edges = [];
			}
			graph.edges = (graph.edges || []).filter(edge => {
				if (edge.container === node.id) {
					node.edges.push(edge);
					return false;
				}
				return true;
			});
		};

		const acquireEdgesRecursive = node => {
			acquireEdges(node);
			if (node.children) {
				node.children.forEach(acquireEdgesRecursive);
			}
		};

		graph.children.forEach(acquireEdgesRecursive);

        //console.log(JSON.stringify(layoutedGraph));

        const svg = await renderGraph(layoutedGraph, options, 1.0);
        const svgOpt = optimize(svg, { multipass: true }).data;
        await fs.writeFile(output, svgOpt);
    });

program.parse();
