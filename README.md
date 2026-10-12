Proteus 9 (Labcenter Electronics) under NixOS via Wine
=====================

# Requirements
- NixOS machine
- A downloaded version of Proteus 9 (can be the demo version)

# Installation


```bash
git clone https://github.com/augu5te/proteus9-nix.git
cd proteus9-nix
# Note: prodemo.exe is the demonstration version, to be replaced 
nix run .#setup -- prodemo.exe
```
# Usage

```bash
cd proteus9-nix
nix run 
```
