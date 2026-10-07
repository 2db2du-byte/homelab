# homelab

Self-hosted apps for the phone/TV, running on this laptop, run with Docker, data on the laptop's internal drive at `~/.local/share/homelab` (moved off the 1TB USB drive 2026-09-27; set by `DATA` in `~/.config/homelab/config`).

The drive is LUKS-encrypted (`system/encrypt-drive.sh`): `/etc/crypttab` unlocks it at boot with
`/etc/cryptsetup-keys.d/homelab.key` (on the encrypted internal drive); a printed recovery key opens it
anywhere else. `homelab start` unlocks it if it was plugged in after boot.

| App | Port | What |
|---|---|---|
| nextcloud | 8080 | files, calendar, contacts |
| paperless | 8000 | scanned paperwork, searchable by text |
| mealie | 9000 | recipes, meal plans, shopping lists |
| homebox | 3100 | inventory, warranties, receipts |
| actual | 5006 | budgeting |
| linkwarden | 3000 | saved & archived web pages |

```
homelab                 # what's running + addresses
homelab start nextcloud # or: homelab start all
homelab stop            # stop everything
homelab update          # new versions
homelab help
```

- Nothing starts at boot. Docker itself starts on first use (socket activation).
- `homelab start` refuses to run unless the drive is mounted and the laptop is on the home
  Wi-Fi (`HOME_SSID` in `~/.config/homelab/config`); `--anywhere` overrides.
- Reachable from the home network: ufw-docker lets private networks reach published ports.
- Only apps used from other devices (phone, TV) live here. Laptop-only tools are regular apps
  instead: PDF Arranger / Evince / Xournal++ for PDFs, Dialect for translation, Joshua for local AI.
- Secrets are generated on first start into `/mnt/homelab/.secrets/` so they travel with the data.
  Each app's `.env` is rewritten on every start (current IP, timezone, secrets).
- `system/setup-system.sh` is the one-time root setup (GIMP, docker group).

## License

MIT. Built by Rabbid Raccoon with Claude. Use it, change it, share it.
