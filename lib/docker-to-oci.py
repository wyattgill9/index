"""Convert a docker-archive tarball (stdin) to an OCI-archive tarball (stdout)."""

import sys
import io
import json
import hashlib
import tarfile


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    entries = {}
    with tarfile.open(fileobj=sys.stdin.buffer, mode="r|") as tar:
        for member in tar:
            f = tar.extractfile(member)
            if f is not None:
                entries[member.name] = f.read()

    docker_manifest = json.loads(entries["manifest.json"])[0]
    config_data = entries[docker_manifest["Config"]]
    config_digest = sha256(config_data)

    oci_layers = []
    for layer_path in docker_manifest["Layers"]:
        data = entries[layer_path]
        oci_layers.append(
            {
                "mediaType": "application/vnd.oci.image.layer.v1.tar",
                "digest": f"sha256:{sha256(data)}",
                "size": len(data),
                "data": data,
            }
        )

    manifest = json.dumps(
        {
            "schemaVersion": 2,
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "config": {
                "mediaType": "application/vnd.oci.image.config.v1+json",
                "digest": f"sha256:{config_digest}",
                "size": len(config_data),
            },
            "layers": [
                {
                    "mediaType": l["mediaType"],
                    "digest": l["digest"],
                    "size": l["size"],
                }
                for l in oci_layers
            ],
        }
    ).encode()
    manifest_digest = sha256(manifest)

    index = json.dumps(
        {
            "schemaVersion": 2,
            "mediaType": "application/vnd.oci.image.index.v1+json",
            "manifests": [
                {
                    "mediaType": "application/vnd.oci.image.manifest.v1+json",
                    "digest": f"sha256:{manifest_digest}",
                    "size": len(manifest),
                }
            ],
        }
    ).encode()

    layout = json.dumps({"imageLayoutVersion": "1.0.0"}).encode()

    def add(tar, name, data):
        ti = tarfile.TarInfo(name)
        ti.size = len(data)
        tar.addfile(ti, io.BytesIO(data))

    with tarfile.open(fileobj=sys.stdout.buffer, mode="w|") as tar:
        add(tar, "oci-layout", layout)
        add(tar, "index.json", index)
        add(tar, f"blobs/sha256/{manifest_digest}", manifest)
        add(tar, f"blobs/sha256/{config_digest}", config_data)
        for layer in oci_layers:
            digest = layer["digest"].removeprefix("sha256:")
            add(tar, f"blobs/sha256/{digest}", layer["data"])


if __name__ == "__main__":
    main()
