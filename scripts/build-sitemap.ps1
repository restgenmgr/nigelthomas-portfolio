name: Generate Sitemap

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  sitemap_job:
    runs-on: ubuntu-latest
    name: Generate a sitemap
    steps:
      - name: Checkout the repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate the sitemap
        shell: pwsh
        run: ./build-sitemap.ps1

      - name: Commit and push the sitemap
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add sitemap.xml
          git commit -m "Automatically generate sitemap" || echo "No changes to commit"
          git push