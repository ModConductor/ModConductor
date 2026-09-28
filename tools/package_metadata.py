"""Shared SPDX inventory shape for desktop payloads."""


def spdx_document(inventory, version, platform_name, platform_slug, manifest_hash, created, creator):
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"ModConductor-{platform_name}-{version}",
        "documentNamespace": f"https://modconductor.invalid/spdx/{platform_slug}/{version}/{manifest_hash}",
        "creationInfo": {"created": created, "creators": [f"Tool: {creator}"]},
        "packages": [{
            "name": "Mod Conductor",
            "SPDXID": "SPDXRef-ModConductor",
            "versionInfo": version,
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": True,
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": "GPL-3.0-or-later",
            "copyrightText": "NOASSERTION",
        }],
        "files": [
            {
                "fileName": "./" + item["path"],
                "SPDXID": f"SPDXRef-File-{index}",
                "checksums": [{"algorithm": "SHA256", "checksumValue": item["sha256"]}],
                "licenseConcluded": "NOASSERTION",
                "copyrightText": "NOASSERTION",
            }
            for index, item in enumerate(inventory)
        ],
        "relationships": [
            {
                "spdxElementId": "SPDXRef-DOCUMENT",
                "relatedSpdxElement": "SPDXRef-ModConductor",
                "relationshipType": "DESCRIBES",
            }
        ] + [
            {
                "spdxElementId": "SPDXRef-ModConductor",
                "relatedSpdxElement": f"SPDXRef-File-{index}",
                "relationshipType": "CONTAINS",
            }
            for index in range(len(inventory))
        ],
    }
