# SHA-1 Hulud Scanner

Et verktøy for å skanne utviklerklienter for SHA-1 Hulud sårbarheter.

## Hva gjør dette scriptet?

Dette scriptet skanner hele filsystemet for følgende potensielt sårbare filer og mapper:
- `setup_bun.js`
- `bun_environment.js`
- `.truffler-cache/` (skjult mappe)

## Bruk

### Kjør direkte fra GitHub med npx

```bash
npx github:navikt/sha1-hulud-scanner#v0.4
```

## Hva skjer når scriptet kjører?

1. **Skanning**: Scriptet søker gjennom hele filsystemet (`/`) etter de filene og mappene som er tydelige indikatorer på en infisert utviklerklient.
2. **Resultatfiler**: Scriptet oppretter markeringsfiler i hjemmemappen din (`~`) som blir lest av Kolide.
