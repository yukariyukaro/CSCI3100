# Security Scans

## Static App Scan (SAST)

- Brakeman: `bundle exec brakeman`

## Dependency Scan (SCA)

- bundler-audit: `bundle exec bundle-audit --update`

## Filesystem / Repo Scan

- Trivy (FS): `trivy fs --severity HIGH,CRITICAL --exit-code 1 .`

## Notes

- CI blocks on HIGH/CRITICAL findings in Trivy, and Brakeman/bundler-audit failures.
- Sensitive changes use step-up authentication (current password required) for community change.

