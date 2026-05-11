# OSTRA

> WIP

**O**ne **S**cript **T**o **R**un 'em **A**ll.

OSTRA is a script that turns a few Proxmox nodes into a small K3s + Longhorn homelab cluster with as little manual work as possible.

## Initial target

OSTRA v1 is aimed at this shape:

- 3 Proxmox nodes reachable over SSH
- 1 VM per Proxmox node
- K3s cluster:
  - 1 server
  - 2 agents
- Longhorn for replicated storage
- Ability to mark one low-power node as mostly storage-only
- Ability to deploy a github repo and listen for changes

## Usage vision

```bash
curl -fsSL https://raw.githubusercontent.com/pablopunk/ostra/main/ostra.sh | bash -s -- apply
```

## Local files

Planned local state:

```text
~/.config/ostra/config.env
~/.config/ostra/state.env
```

- `config.env`: user-provided desired settings
- `state.env`: generated stable IDs, IPs, and discovered values

