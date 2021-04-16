# git partial checkout

How to checkout just one directory from a git repo (from https://stackoverflow.com/a/52269934).

## using sparse checkouts

```
git clone \
  --depth 1  \
  --filter=blob:none  \
  --sparse \
  https://github.com/big/repo \
;
cd repo
git sparse-checkout init --cone
git sparse-checkout set <small-directory>
```

## using no-checkout

```
git clone \
  --depth 1  \
  --filter=blob:none  \
  --no-checkout \
  https://github.com/big/repo \
;
cd repo
git checkout master -- <small directory>
```

