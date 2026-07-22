# cgit-docker

Self-hosted git repository browser using [cgit](https://git.zx2c4.com/cgit), built from source with Docker.

## Quick Start

```bash
cp cgitrc.example cgitrc && vim cgitrc # Edit cgitrc first

mkdir secrets && touch secrets/authorized_keys
vim secrets/authorized_keys # Put your pub_key

docker compose up -d --build
```

- **Web UI:** `http://localhost:8090`
- **SSH Push:** `ssh://git@localhost:2222`

Repos are auto-created on first push. HTTP clone, SSH pull and push is accepted.

> **Note:** Default branch name is `main`, not `master`.

You can edit `secrets/authorized_keys` on the fly, changes will sync automatically.

## Repo metadata

In your repo:

```bash
git config gitweb.description "description"    # Edit "Description"

git config gitweb.owner "rein"                 # Edit "Owner"

git config gitweb.category "name"              # Edit "Section"
```

