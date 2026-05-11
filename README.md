# OSTRA

> WIP

**O**ne **S**cript **T**o **R**un 'em **A**ll.

OSTRA is a script that turns a few Proxmox nodes into a small K3s + Longhorn homelab cluster with as little manual work as possible.

## Features

<img width="510" height="663" alt="CleanShot 2026-05-11 at 20 33 49@2x" src="https://github.com/user-attachments/assets/6f98fbd6-5b97-4651-b526-b14368037948" />

- 3 Proxmox nodes
- 1 VM per Proxmox node
- K3s cluster:
  - 1 server
  - 2 agents
- Longhorn for replicated storage
- Ability to mark one low-power node as mostly storage-only
- Ability to deploy a github repo and listen for changes

## Usage vision

```bash
curl -fsSL https://raw.githubusercontent.com/pablopunk/ostra/main/ostra.sh | bash -s
```

## Local files

Planned local state:

```text
~/.config/ostra/config.env
~/.config/ostra/state.env
```

- `config.env`: user-provided desired settings
- `state.env`: generated stable IDs, IPs, and discovered values

