#!/usr/bin/env bash

for f in $(ls *.typ); do typst c $f --pdf-standard=a-3u; done && rm -f combined.pdf && pdfunite *.pdf combined.pdf