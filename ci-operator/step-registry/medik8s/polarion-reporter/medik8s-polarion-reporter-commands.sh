#!/bin/bash
set -eu -o pipefail

POLARION_USER=$(cat /var/run/polarion/username)
POLARION_PASS=$(cat /var/run/polarion/password)
IMPORT_URL="${POLARION_URL}/polarion/import/xunit"

echo "Collecting JUnit XML files from \$SHARED_DIR..."
xml_files=("${SHARED_DIR}"/*_junit.xml)

if [[ ! -e "${xml_files[0]}" ]]; then
  echo "No *_junit.xml files found in \$SHARED_DIR — skipping Polarion import."
  exit 0
fi

echo "Found ${#xml_files[@]} file(s): ${xml_files[*]}"

# Build properties file for the XUnit importer.
# polarion-project-id and polarion-testrun-id are read by Polarion from this
# companion file when present alongside the XML in a multipart POST.
properties_file=$(mktemp /tmp/polarion-props.XXXXXX.xml)
cat > "${properties_file}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites-importer>
  <properties>
    <property name="polarion-project-id" value="${POLARION_PROJECT_ID}"/>
$([ -n "${POLARION_TESTRUN_ID}" ] && echo "    <property name=\"polarion-testrun-id\" value=\"${POLARION_TESTRUN_ID}\"/>")
  </properties>
</testsuites-importer>
EOF

for xml_file in "${xml_files[@]}"; do
  echo "Importing $(basename "${xml_file}") into Polarion project ${POLARION_PROJECT_ID}..."
  http_code=$(curl --silent --output /tmp/polarion-response.txt --write-out "%{http_code}" \
    -u "${POLARION_USER}:${POLARION_PASS}" \
    -F "file=@${xml_file}" \
    -F "properties=@${properties_file}" \
    "${IMPORT_URL}")

  if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
    echo "Import succeeded (HTTP ${http_code})."
  else
    echo "Import failed (HTTP ${http_code}):"
    cat /tmp/polarion-response.txt
    exit 1
  fi
done
