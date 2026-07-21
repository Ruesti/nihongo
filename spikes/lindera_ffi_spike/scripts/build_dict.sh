#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/build_dict.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v lindera >/dev/null 2>&1; then
  cargo install lindera-cli --version 4.0.1
fi

curl -L -o /tmp/mecab-ipadic-2.7.0-20250920.tar.gz \
  "https://lindera.dev/mecab-ipadic-2.7.0-20250920.tar.gz"
rm -rf /tmp/mecab-ipadic-2.7.0-20250920
mkdir -p /tmp/mecab-ipadic-2.7.0-20250920
tar zxf /tmp/mecab-ipadic-2.7.0-20250920.tar.gz -C /tmp/mecab-ipadic-2.7.0-20250920 --strip-components=1

curl -L -o /tmp/ipadic-metadata.json \
  "https://raw.githubusercontent.com/lindera/lindera/main/lindera-ipadic/metadata.json"

mkdir -p dict
lindera build \
  --src /tmp/mecab-ipadic-2.7.0-20250920 \
  --dest dict/lindera-ipadic-2.7.0-20250920 \
  --metadata /tmp/ipadic-metadata.json

echo "Dictionary built at dict/lindera-ipadic-2.7.0-20250920"
du -sh dict/lindera-ipadic-2.7.0-20250920
