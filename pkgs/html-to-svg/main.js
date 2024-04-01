import fs from "node:fs/promises";
import satori from "satori";
import { html } from "satori-html";
import { Command } from "commander";

const program = new Command();

program
  .name("html-to-svg")
  .description("Convert satori compatible HTML to SVG")
  .version("1.0.0")
  .argument("<input>", "satori html file to render")
  .argument("<output>", "output svg")
  .option("--font <font>", "Sets the font")
  .option("--font-bold <font>", "Sets the bold font")
  .option("-w, --width <width>", "Sets the width of the output. Use auto for automatic scaling.", "auto")
  .option("-h, --height <height>", "Sets the height of the output. Use auto for automatic scaling.", "auto")
  .action(async (input, output, options) => {
    if (!options.font) {
      console.error("--font is required");
      process.exit(1);
    }

    if (!options.fontBold) {
      console.error("--font-bold is required");
      process.exit(1);
    }

    const markup = html(await fs.readFile(input, { encoding: "utf8" }));
    const svg = await satori(markup, {
      ...(options.width != "auto" && {width: options.width}),
      ...(options.height != "auto" && {height: options.height}),
      embedFont: true,
      fonts: [
        {
          name: "Font",
          data: await fs.readFile(options.font),
          weight: 400,
          style: "normal",
        },
        {
          name: "Font",
          data: await fs.readFile(options.fontBold),
          weight: 700,
          style: "normal",
        },
      ],
    });

    await fs.writeFile(output, svg);
  });

program.parse();
