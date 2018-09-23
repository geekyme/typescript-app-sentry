## Demo app

This is a demo app in TS reporting errors to sentry, with source map enabled. This uses `scripts/release.sh` to orchestrate building the `dist/` folder and uploading the contents to sentry

Set your env variables before creating a release via `scripts/release.sh`

## Deployment

You will need to set up your sentry cluster first. For sentry deployment in Kubernetes See [sentry](sentry/)
