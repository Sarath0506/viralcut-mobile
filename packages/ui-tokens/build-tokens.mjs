import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(__dirname, "tokens.json"), "utf8"));

function cssVars(mode) {
  const lines = Object.entries(tokens.color).map(([key, value]) => {
    const hex = value[mode];
    const cssKey = key.replace(/([A-Z])/g, "-$1").toLowerCase();
    return `  --vc-${cssKey}: ${hex};`;
  });
  return lines.join("\n");
}

const webCss = `/* Generated from packages/ui-tokens/tokens.json — do not edit by hand */
:root {
${cssVars("light")}
}

.dark {
${cssVars("dark")}
}
`;

const outWeb = join(__dirname, "dist", "web.css");
mkdirSync(dirname(outWeb), { recursive: true });
writeFileSync(outWeb, webCss);

const flutterColors = Object.entries(tokens.color)
  .map(([key, value]) => {
    const camel = key.replace(/Variant/g, "Variant");
    const light = value.light.replace("#", "0xFF");
    const dark = value.dark.replace("#", "0xFF");
    return `  static const ${camel}Light = Color(${light});\n  static const ${camel}Dark = Color(${dark});`;
  })
  .join("\n");

const flutterDart = `// Generated from packages/ui-tokens/tokens.json — do not edit by hand
import 'package:flutter/material.dart';

abstract final class ViralCutTokenColors {
${flutterColors}
  static const deepSurface = deepSurfaceDark;
}
`;

const outFlutterLib = join(__dirname, "lib", "viralcut_token_colors.dart");
mkdirSync(dirname(outFlutterLib), { recursive: true });
writeFileSync(outFlutterLib, flutterDart);

console.log("Built ui-tokens:", outWeb, outFlutterLib);
