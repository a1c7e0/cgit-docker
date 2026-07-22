# cgit-docker

Self-hosted git repository browser using [cgit](https://git.zx2c4.com/cgit), built from source with Docker.

## Quick Start

```bash
cp cgitrc.example cgitrc && vim cgitrc # Edit cgitrc first

mkdir secrets && touch secrets/authorized_keys
vim secrets/authorized_keys # Put your pub_key

docker compose up -d
```

- **Web UI:** `http://localhost:8090`
- **SSH Push:** `ssh://git@localhost:2222`

Repo will be auto-created on the first push. HTTP clone, SSH pull and push are accepted.

> **Note:** Default branch name is `main`, not `master`.

You can edit `secrets/authorized_keys` on the fly, changes will sync every 30 seconds.

## Repo metadata

```bash
# Edit "Description"
ssh -p 2222 git@localhost "git -C /var/lib/git/repo config gitweb.description 'description'"

# Edit "Owner"
ssh -p 2222 git@localhost "git -C /var/lib/git/repo config gitweb.owner 'name'"

# Edit "Section"
ssh -p 2222 git@localhost "git -C /var/lib/git/repo config gitweb.category 'section'"
```

## License

[GPL-2.0](LICENSE)

The filter scripts under `filters/` are derived from [cgit](https://github.com/zx2c4/cgit) (GPL-2.0).

