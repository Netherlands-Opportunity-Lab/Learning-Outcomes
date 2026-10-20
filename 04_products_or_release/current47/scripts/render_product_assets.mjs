// Render only the unchanged outlined logo. Plot PNGs are produced directly by
// R/ragg: reinterpreting svglite CSS in another renderer can fill line paths.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
const [repo,out,fonts]=process.argv.slice(2);
if(!fonts)throw Error('Usage: node render_product_assets.mjs repo paper-figures fonts');
const modules=process.env.LO_NODE_MODULES;
if(!modules)throw Error('Set LO_NODE_MODULES to the documented runtime');
const require=createRequire(path.join(modules,'@oai/artifact-tool/package.json'));
const {FontLibrary,Canvas,loadImage}=require('skia-canvas');
FontLibrary.use('Oswald',[path.join(fonts,'font2.ttf')]);
FontLibrary.use('Oswald Medium',[path.join(fonts,'font3.ttf')]);
const logo=await loadImage(path.join(repo,'05_publication/preview_overlay/assets/brand/leerprestaties_nl.svg'));
const canvas=new Canvas(1064,292),ctx=canvas.getContext('2d');
ctx.drawImage(logo,0,0,1064,292);
await fs.writeFile(path.join(out,'leerprestaties-logo.png'),await canvas.toBuffer('png'));
console.log('UNCHANGED_OUTLINED_LOGO_RENDERED; scientific plots use native R/ragg');
