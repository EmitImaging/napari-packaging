import os
import shutil
from pathlib import Path


def main() -> None:
    prefix = Path(os.environ["PREFIX"])
    src_dir = Path(os.environ["SRC_DIR"])
    pkg_version = os.environ["PKG_VERSION"]

    # This comes from the rattler-build recipe variable substitution.
    # If it doesn't exist, fall back to SRC_DIR.
    local_src = r"""${{ local_napari_source }}""".strip()
    src_root = Path(local_src) if local_src else src_dir
    if not src_root.exists():
        src_root = src_dir

    menu_dir = prefix / "Menu"
    menu_dir.mkdir(parents=True, exist_ok=True)

    # Write menu json with version substituted
    src_cfg = src_root / "resources" / "conda_menu_config.json"
    if not src_cfg.exists():
        raise FileNotFoundError(f"Missing {src_cfg}")

    out_cfg = menu_dir / "napari-menu.json"
    text = src_cfg.read_text(encoding="utf-8")
    out_cfg.write_text(text.replace("__PKG_VERSION__", pkg_version), encoding="utf-8")

    # Copy icons if they exist
    to_copy = [
        (src_root / "src" / "napari" / "resources" / "logo.png", menu_dir / "napari.png"),
        (src_root / "src" / "napari" / "resources" / "icon.icns", menu_dir / "napari.icns"),
        (src_root / "src" / "napari" / "resources" / "icon.ico", menu_dir / "napari.ico"),
    ]
    for src, dst in to_copy:
        if src.exists():
            shutil.copy2(src, dst)


if __name__ == "__main__":
    main()
