SHELL := bash

.PHONY: check build iso switch local update fmt test-backup test-vault bump ship release release-major do-release publish

VERSION_FILE = VERSION
CHANGELOG = CHANGELOG.md
EDITOR ?= hx
# The tag marks the version; the release marks the artifact. So bump tags and
# stops, and PUBLISH=0 only skips the ISO build and the GitHub release.
PUBLISH ?= 1
SIGNKEY ?= $(HOME)/.ssh/nixriot.pub
SECKEY ?= $(HOME)/.ssh/nixriot

check:
	nix flake check

build:
	nix build .#nixosConfigurations.nixriot.config.system.build.toplevel

iso:
	nix build .#iso

switch:
	sudo nixos-rebuild switch --flake .#nixriot

# Build and activate the working tree on this machine, without touching
# /etc/nixriot and without pushing anything.
local:
	@set -euo pipefail; \
	  dst=/tmp/nixriot-candidate; \
	  rm -rf "$$dst"; \
	  mkdir -p "$$dst"; \
	  rsync -a --exclude .git "$(CURDIR)/" "$$dst/"; \
	  cp /etc/nixriot/hosts/installed/local.nix \
	     /etc/nixriot/hosts/installed/hardware-configuration.nix "$$dst/hosts/installed/"; \
	  if [ -f /etc/nixriot/hosts/installed/features.nix ]; then \
	    cp /etc/nixriot/hosts/installed/features.nix "$$dst/hosts/installed/"; \
	  fi; \
	  sudo nixos-rebuild switch --flake "$$dst#installed"

update:
	nix flake update

fmt:
	nix fmt

# Exercise the backup script end to end in /tmp. NIXRIOT_BACKUP_TEST=1 makes the
# script skip the mount, encryption and space guards, so it runs against a
# scratch directory instead of a real drive.
test-backup:
	@set -euo pipefail; \
	  t=$$(mktemp -d /tmp/nixriot-backup-test.XXXXXX); \
	  trap 'rm -rf "$$t"' EXIT; \
	  mkdir -p "$$t/src/sub" "$$t/dst/home"; \
	  head -c 33554432 /dev/urandom > "$$t/src/big.bin"; \
	  printf 'one\n' > "$$t/src/one.txt"; \
	  printf 'two\n' > "$$t/src/sub/two.txt"; \
	  printf 'stale\n' > "$$t/dst/home/stale.txt"; \
	  run() { HOME="$$t/src" NIXRIOT_BACKUP_TEST=1 bash panacea/panacea/scripts/backup.sh "$$@"; }; \
	  echo "== first run"; \
	  run backup "$$t/dst" > "$$t/first.out"; cat "$$t/first.out"; \
	  rg -q '^PLAN files=3 bytes=[0-9]+ deletes=1 free=' "$$t/first.out"; \
	  rg -q '^DONE ok' "$$t/first.out"; \
	  test -f "$$t/dst/home/one.txt" && test -f "$$t/dst/home/sub/two.txt"; \
	  test -f "$$t/dst/home/big.bin" && test ! -e "$$t/dst/home/stale.txt"; \
	  test -f "$$t/dst/system/manifest.txt"; \
	  echo "== second run, nothing changed"; \
	  run backup "$$t/dst" > "$$t/second.out"; cat "$$t/second.out"; \
	  rg -q '^PLAN files=0 bytes=0 deletes=0' "$$t/second.out"; \
	  rg -q '^DONE ok' "$$t/second.out"; \
	  echo "== a new file"; \
	  printf 'three\n' > "$$t/src/three.txt"; \
	  run backup "$$t/dst" > "$$t/third.out"; \
	  test -f "$$t/dst/home/three.txt" && rg -q '^DONE ok' "$$t/third.out"; \
	  echo "== verify"; \
	  run verify "$$t/dst" > "$$t/verify.out"; cat "$$t/verify.out"; \
	  rg -q '^DONE ok' "$$t/verify.out"; \
	  echo "== an unmounted directory is not a drive"; \
	  HOME="$$t/src" bash panacea/panacea/scripts/backup.sh status "$$t/dst" > "$$t/status.out"; \
	  cat "$$t/status.out"; \
	  rg -qx 'mounted=no' "$$t/status.out"; \
	  echo "== cancel through a scope"; \
	  head -c 268435456 /dev/urandom > "$$t/src/huge.bin"; \
	  systemd-run --user --scope --collect --quiet --unit=panacea-backup-test \
	    env HOME="$$t/src" NIXRIOT_BACKUP_TEST=1 NIXRIOT_BACKUP_BWLIMIT=10000 \
	    bash panacea/panacea/scripts/backup.sh backup "$$t/dst" > "$$t/cancel.out" 2>&1 & \
	  sleep 3; \
	  systemctl --user kill --signal=SIGTERM panacea-backup-test.scope || true; \
	  wait || true; \
	  for _ in 1 2 3 4 5 6 7 8 9 10; do \
	    pgrep -f "[r]sync .*nixriot-backup-test" >/dev/null || break; \
	    sleep 0.5; \
	  done; \
	  if pgrep -f "[r]sync .*nixriot-backup-test" >/dev/null; then \
	    echo "FAIL: rsync survived the cancel"; exit 1; \
	  fi; \
	  cat "$$t/cancel.out"; \
	  rg -q '^DONE cancelled' "$$t/cancel.out"; \
	  echo "== test-backup: OK"

# Exercise the vault end to end in a scratch HOME. A failing pinentry is first
# in PATH, so the test proves the GPG calls never reach pinentry or the agent.
test-vault:
	@set -euo pipefail; \
	  t=$$(mktemp -d /tmp/nixriot-vault-test.XXXXXX); \
	  trap 'rm -rf "$$t"' EXIT; \
	  mkdir -p "$$t/home/.gnupg" "$$t/run" "$$t/fake"; \
	  printf '#!/bin/sh\necho invoked >> "%s/marker"\nexit 1\n' "$$t" > "$$t/fake/pinentry"; \
	  chmod +x "$$t/fake/pinentry"; \
	  printf 'pinentry-program %s/pinentry\n' "$$t/fake" > "$$t/home/.gnupg/gpg-agent.conf"; \
	  chmod 700 "$$t/home/.gnupg"; \
	  home="$$t/home"; \
	  store="$$home/.local/share/panacea/vault.enc"; \
	  v=panacea/panacea/scripts/vault.sh; \
	  run() { HOME="$$home" XDG_RUNTIME_DIR="$$t/run" DISPLAY= WAYLAND_DISPLAY= GPG_TTY= \
	          PATH="$$t/fake:$$PATH" sh "$$v" "$$@"; }; \
	  echo "== save and load"; \
	  printf 'pw\n[{"id":"1","label":"x"}]\n' | run save; \
	  test "$$(printf 'pw\n' | run load)" = '[{"id":"1","label":"x"}]'; \
	  test ! -e "$$t/marker" || { echo "FAIL: pinentry was invoked"; exit 1; }; \
	  echo "== wrong password"; \
	  if printf 'wrong\n' | run load >/dev/null 2>&1; then \
	    echo "FAIL: a wrong password opened the vault"; exit 1; \
	  fi; \
	  echo "== tampered store"; \
	  cp "$$store" "$$t/good"; \
	  printf '\000' | dd of="$$store" bs=1 seek=40 conv=notrunc status=none; \
	  if printf 'pw\n' | run load >/dev/null 2>&1; then \
	    echo "FAIL: a tampered store opened"; exit 1; \
	  fi; \
	  cp "$$t/good" "$$store"; \
	  echo "== legacy openssl store"; \
	  printf pw > "$$t/pwfile"; \
	  printf '[{"id":"old"}]' | openssl enc -aes-256-cbc -pbkdf2 -iter 240000 \
	    -salt -out "$$store" -pass file:"$$t/pwfile"; \
	  test "$$(printf 'pw\n' | run load)" = '[{"id":"old"}]'; \
	  echo "== wipe"; \
	  run wipe; \
	  test ! -e "$$store"; \
	  test ! -e "$$t/marker" || { echo "FAIL: pinentry was invoked"; exit 1; }; \
	  echo "== test-vault: OK"

# Bump the version, commit and tag it, so installed machines see the update,
# without building an ISO or creating a GitHub release. 'make release' then
# publishes that same version.
bump:
	@$(MAKE) --no-print-directory do-release BUMP=minor PUBLISH=0

# Bump and publish to installed machines without building an ISO or creating a
# GitHub release. The version and tag are the whole change: machines compare
# VERSION with main, so pushing both is the release.
ship:
	@$(MAKE) --no-print-directory do-release BUMP=minor PUBLISH=0
	git push origin main
	git push origin "v$$(cat VERSION)"

release:
	@$(MAKE) --no-print-directory do-release BUMP=minor

release-major:
	@$(MAKE) --no-print-directory do-release BUMP=major

do-release:
	@set -euo pipefail; \
	  old=$$(cat $(VERSION_FILE)); \
	  major=$${old%%.*}; \
	  minor=$${old#*.}; \
	  if [ -n "$$(git tag -l "v$$old")" ]; then \
	    if [ "$(PUBLISH)" = 1 ] && gh auth status >/dev/null 2>&1 && ! gh release view "v$$old" >/dev/null 2>&1; then \
	      echo "v$$old is tagged but not published. Publishing it now."; \
	      $(MAKE) --no-print-directory do-publish; \
	      exit 0; \
	    fi; \
	    section=Unreleased; \
	    case "$(BUMP)" in \
	      minor) new="$$major.$$((minor + 1))" ;; \
	      major) new="$$((major + 1)).0" ;; \
	      *) echo "usage: make release | make release-major"; exit 1 ;; \
	    esac; \
	  else \
	    section="$$old"; \
	    new="$$old"; \
	    echo "v$$old has no tag yet: releasing it as it stands."; \
	  fi; \
	  notes() { \
	    awk -v h="## $$section" \
	      '$$0 == h { f = 1; next } /^## / { f = 0 } f && /^- / { print }' $(CHANGELOG); \
	  }; \
	  if [ -z "$$(notes)" ]; then \
	    line=$$(awk -v h="## $$section" '$$0 == h { print NR + 1; exit }' $(CHANGELOG)); \
	    echo "No notes under '## $$section'. Write bullets under it in $(CHANGELOG) (line $$line)."; \
	    $(EDITOR) $(CHANGELOG) || echo "The editor exited with an error."; \
	  fi; \
	  [ -n "$$(notes)" ] || { \
	    echo "Still nothing under '## $$section'. Nothing released."; \
	    echo "Add bullets under '## $$section' in $(CHANGELOG), then run make release again."; \
	    exit 1; \
	  }; \
	  if [ "$$section" = "Unreleased" ]; then \
	    if [ "$(PUBLISH)" = 1 ]; then echo "Releasing $$old -> $$new"; else echo "Bumping $$old -> $$new"; fi; \
	    awk -v new="## $$new" \
	      '/^## Unreleased/ { print "## Unreleased"; print ""; print new; next } { print }' \
	      $(CHANGELOG) > $(CHANGELOG).tmp; \
	    mv $(CHANGELOG).tmp $(CHANGELOG); \
	    printf '%s\n' "$$new" > $(VERSION_FILE); \
	  fi; \
	  sed -i "s|badge/version-[0-9.]*-|badge/version-$$new-|" README.md; \
	  if [ "$(PUBLISH)" = 1 ]; then msg="Release $$new"; else msg="Version $$new"; fi; \
	  if [ -n "$$(git status --porcelain)" ]; then \
	    git add -A; \
	    echo; \
	    git --no-pager diff --cached --stat; \
	    echo; \
	    read -r -p "Commit everything as '$$msg'? [y/N] " commit_answer; \
	    case "$$commit_answer" in \
	      y|Y) ;; \
	      *) \
	        git reset -q; \
	        git checkout HEAD -- $(VERSION_FILE) $(CHANGELOG) README.md; \
	        echo "Nothing committed or tagged. The release files were put back."; \
	        exit 0; \
	        ;; \
	    esac; \
	    git commit -q -m "$$msg"; \
	  fi; \
	  git -c gpg.format=ssh -c user.signingkey=$(SIGNKEY) tag -s "v$$new" -m "NixRiot v$$new"; \
	  echo "Tagged v$$new."; \
	  if [ "$(PUBLISH)" = 1 ]; then \
	    $(MAKE) --no-print-directory do-publish; \
	  else \
	    echo "No ISO built. 'make release' publishes v$$new when it is wanted."; \
	  fi

publish:
	@$(MAKE) --no-print-directory do-publish

do-publish:
	@set -euo pipefail; \
	  ver=$$(cat $(VERSION_FILE)); \
	  gh auth status >/dev/null 2>&1 || { \
	    echo "gh is not authenticated. Run 'gh auth login' first."; \
	    exit 1; \
	  }; \
	  [ -z "$$(git status --porcelain)" ] || { \
	    echo "The working tree is dirty. Commit or stash before publishing v$$ver."; \
	    git status --short; \
	    exit 1; \
	  }; \
	  tag=$$(git rev-parse "v$$ver^{commit}" 2>/dev/null || true); \
	  [ "$$tag" = "$$(git rev-parse HEAD)" ] || { \
	    echo "HEAD is not the commit tagged v$$ver. Check out the tag before publishing."; \
	    exit 1; \
	  }; \
	  echo "Publishing v$$ver at commit $$tag."; \
	  echo "Building the ISO for v$$ver. This takes a few minutes."; \
	  nix build .#iso; \
	  sha256sum result/iso/NixRiot.iso | sed 's| result/iso/|  |' > SHA256SUMS; \
	  ssh-keygen -Y sign -f $(SECKEY) -n file SHA256SUMS; \
	  notes() { \
	    awk -v h="## $$ver" '$$0 == h { f = 1; next } /^## / { f = 0 } f' $(CHANGELOG); \
	  }; \
	  echo; \
	  echo "About to publish v$$ver to github.com/CyphrRiot/NixRiot:"; \
	  echo "  result/iso/NixRiot.iso  ($$(du -h result/iso/NixRiot.iso | cut -f1))"; \
	  echo "  SHA256SUMS"; \
	  echo "  SHA256SUMS.sig"; \
	  echo; \
	  releases=$$(gh release list --limit 200 --json tagName -q '.[].tagName' | sort -V || true); \
	  keep_newest=$$(printf '%s\n' "$$releases" | grep -vxF "v$$ver" | tail -n 1 || true); \
	  stale=$$(printf '%s\n' "$$releases" | grep -vxF "v$$ver" | grep -vxF "$$keep_newest" || true); \
	  if [ -n "$$stale" ]; then \
	    echo "Old releases that will be deleted (v$$ver and $$keep_newest are kept):"; \
	    echo "$$stale" | sed 's/^/  /'; \
	    echo; \
	  fi; \
	  read -r -p "Push main and the tag, create the release, and delete the old ones? [Y/n] " answer; \
	  case "$$answer" in n|N) echo "Nothing published. Re-run 'make publish' when ready."; exit 0 ;; *) ;; esac; \
	  git push origin main; \
	  git push origin "v$$ver"; \
	if gh release view "v$$ver" >/dev/null 2>&1; then \
		gh release upload "v$$ver" result/iso/NixRiot.iso SHA256SUMS SHA256SUMS.sig --clobber; \
		gh release edit "v$$ver" --title "NixRiot v$$ver" --notes-file <(notes); \
	else \
		gh release create "v$$ver" --title "NixRiot v$$ver" --notes-file <(notes) \
			result/iso/NixRiot.iso SHA256SUMS SHA256SUMS.sig; \
	fi; \
	  gh release edit "v$$ver" --draft=false >/dev/null; \
	  for f in NixRiot.iso SHA256SUMS SHA256SUMS.sig; do \
	    gh release view "v$$ver" --json assets --jq '.assets[].name' | rg -qx "$$f" || { \
	      echo "v$$ver is missing $$f, or is still a draft."; \
	      exit 1; \
	    }; \
	  done; \
	  echo "Published v$$ver."; \
	  if [ -n "$$stale" ]; then \
	    echo "$$stale" | while read -r old; do gh release delete "$$old" --yes; done; \
	  fi
