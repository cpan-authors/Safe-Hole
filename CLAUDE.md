# CLAUDE.md - Safe::Hole

## Build & Test

```bash
perl Makefile.PL && make && make test
```

## Pull Request Rules

- Do NOT update `Changes` as part of submitted pull requests. The maintainer updates Changes at release time.
- MANIFEST must always be updated when a new file is added to the distribution.
- `README.md` is generated from POD: `pod2markdown lib/Safe/Hole.pm > README.md`
- Do NOT commit a plain `README` file — only `README.md` is used.
