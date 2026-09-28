from pathlib import Path
import shutil
root=Path(__file__).resolve().parents[1]
out=root/'dist'
if out.exists(): shutil.rmtree(out)
out.mkdir()
for name in ['index.html','downloads.html']:
 shutil.copy2(root/name,out/name)
for name in ['product_data','product_figures']:
 shutil.copytree(root/name,out/name)
(out/'assets').mkdir();(out/'docs').mkdir()
for name in ['app-product.js','styles.css']:shutil.copy2(root/'assets'/name,out/'assets'/name)
for name in ['SCIENTIFIC_BOUNDARIES.md','PUBLICATION_STATUS.md','DATA_CONTRACT.md']:shutil.copy2(root/'docs'/name,out/'docs'/name)
print('Static product build complete')
