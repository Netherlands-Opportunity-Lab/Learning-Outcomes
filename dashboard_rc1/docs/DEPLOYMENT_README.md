# Deployment

The complete tested Step-3 artifact is a static site. No server-side code is required.

## Local

Run `python -m http.server 8000` from the extracted `PISA_PIRLS_DASHBOARD_RC1_FINAL_REPO.zip` root.

## GitHub Pages

A Pages workflow is included in the complete repo ZIP. On a repository where Pages is enabled for GitHub Actions, merging the complete dashboard snapshot to the deployment branch can publish the repository root.

## Other static hosts

Upload the complete repository root to Netlify, Cloudflare Pages, S3/CloudFront, Azure Static Web Apps or any ordinary static web server. No build command is required.

## Privacy and publication gate

Do not add raw PISA/PIRLS microdata. Do not make the PIRLS-derived public download layer live until the existing IEA rights gate is resolved.
