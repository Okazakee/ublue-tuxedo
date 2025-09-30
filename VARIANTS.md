# All 36 Universal Blue Tuxedo Variants

This document lists all 36 image variants built by this repository.

## Aurora (KDE Plasma) - 8 variants

| Package Name              | Variants       | Base Image                          |
| ------------------------- | -------------- | ----------------------------------- |
| `aurora-tuxedo`           | stable, latest | `ghcr.io/ublue-os/aurora`           |
| `aurora-tuxedo-dx`        | stable, latest | `ghcr.io/ublue-os/aurora-dx`        |
| `aurora-nvidia-tuxedo`    | stable, latest | `ghcr.io/ublue-os/aurora-nvidia`    |
| `aurora-dx-nvidia-tuxedo` | stable, latest | `ghcr.io/ublue-os/aurora-dx-nvidia` |

## Bluefin (GNOME) - 8 variants

| Package Name               | Variants       | Base Image                           |
| -------------------------- | -------------- | ------------------------------------ |
| `bluefin-tuxedo`           | stable, latest | `ghcr.io/ublue-os/bluefin`           |
| `bluefin-tuxedo-dx`        | stable, latest | `ghcr.io/ublue-os/bluefin-dx`        |
| `bluefin-nvidia-tuxedo`    | stable, latest | `ghcr.io/ublue-os/bluefin-nvidia`    |
| `bluefin-dx-nvidia-tuxedo` | stable, latest | `ghcr.io/ublue-os/bluefin-dx-nvidia` |

## Bazzite (Gaming/Desktop/Deck) - 20 variants

### Gaming (KDE Plasma - Gaming Focused) - 6 variants

| Package Name                 | Variants       | Base Image                             |
| ---------------------------- | -------------- | -------------------------------------- |
| `bazzite-tuxedo`             | stable, latest | `ghcr.io/ublue-os/bazzite`             |
| `bazzite-nvidia-tuxedo`      | stable, latest | `ghcr.io/ublue-os/bazzite-nvidia`      |
| `bazzite-nvidia-open-tuxedo` | stable, latest | `ghcr.io/ublue-os/bazzite-nvidia-open` |

### GNOME (Desktop Experience) - 6 variants

| Package Name                       | Variants       | Base Image                                   |
| ---------------------------------- | -------------- | -------------------------------------------- |
| `bazzite-gnome-tuxedo`             | stable, latest | `ghcr.io/ublue-os/bazzite-gnome`             |
| `bazzite-gnome-nvidia-tuxedo`      | stable, latest | `ghcr.io/ublue-os/bazzite-gnome-nvidia`      |
| `bazzite-gnome-nvidia-open-tuxedo` | stable, latest | `ghcr.io/ublue-os/bazzite-gnome-nvidia-open` |

### Deck (Steam Deck Experience) - 8 variants

| Package Name                       | Variants       | Base Image                                   |
| ---------------------------------- | -------------- | -------------------------------------------- |
| `bazzite-deck-tuxedo`              | stable, latest | `ghcr.io/ublue-os/bazzite-deck`              |
| `bazzite-deck-nvidia-tuxedo`       | stable, latest | `ghcr.io/ublue-os/bazzite-deck-nvidia`       |
| `bazzite-deck-gnome-tuxedo`        | stable, latest | `ghcr.io/ublue-os/bazzite-deck-gnome`        |
| `bazzite-deck-nvidia-gnome-tuxedo` | stable, latest | `ghcr.io/ublue-os/bazzite-deck-nvidia-gnome` |

---

## Total Count

- **36 Containerfiles** (image variants with stable/latest tags)
- **18 GitHub Packages** (each package contains stable + latest tags)
- **36 Base Images** tracked for automated updates

## Package vs Variant Terminology

- **Package**: A named container image in GHCR (e.g., `aurora-tuxedo`)
- **Variant**: A specific tag of a package (e.g., `aurora-tuxedo:stable`, `aurora-tuxedo:latest`)
- **Containerfile**: The build definition for each variant

This repository matches BrickMan240's 18-package structure but with **Aurora NVIDIA variants** added for completeness!
