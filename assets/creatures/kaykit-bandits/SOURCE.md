# KayKit Adventurers, enemy variants (bandits)

- Author: Kay Lousberg, https://kaylousberg.itch.io/kaykit-adventurers (GitHub: KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0)
- License: CC0 1.0 (LICENSE.txt is the pack's own file; no attribution required)
- Derived 2026-10-30 from `assets/characters/kaykit-adventurers/*.glb` with gltf-transform (node API: dispose the
  listed weapon nodes, then `prune`). The source rigs carry every weapon mesh at once; each copy here keeps one kit
  so the bandit reads as one silhouette. Rigs, 76 clips and textures are unchanged.
  - Knight.glb: keeps 1H_Sword + Round_Shield (dropped 1H_Sword_Offhand, Badge/Rectangle/Spike_Shield, 2H_Sword)
  - Barbarian.glb: keeps 2H_Axe (dropped 1H_Axe, 1H_Axe_Offhand, Barbarian_Round_Shield, Mug)
  - Mage.glb: keeps 2H_Staff (dropped 1H_Wand, Spellbook, Spellbook_open)
  - Rogue.glb: keeps Knife + Knife_Offhand (dropped 1H_Crossbow, 2H_Crossbow, Throwable)
  - Rogue_Hooded.glb: keeps 2H_Crossbow (dropped Knife, Knife_Offhand, 1H_Crossbow, Throwable)
- Used only as Bandit Village enemies (Footpad, Crossbowman, Quack, Bruiser, Bandit King boss); players keep their own avatar (see Classes).
