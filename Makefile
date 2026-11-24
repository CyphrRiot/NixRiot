SHELL := bash

.PHONY: check build iso switch update fmt bump ship release release-major do-release publish

VERSION_FILE = VERSION
CHANGELOG = CHANGELOG.md
EDITOR ?= hx
# The tag marks the version; the release marks the artifact. So bump tags and
# stops, and PUBLISH=0 only skips the ISO build and the GitHub release.
PUBLISH ?= 1
SIGNKEY ?= $(HOME)/.ssh/nixriot.pub

check:
	nix flake check

build:
	nix build .#nixosConfigurations.nixriot.config.system.build.toplevel

iso:
	nix build .#iso

switch:
	sudo nixos-rebuild switch --flake .#nixriot

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
	  echo "Building the ISO for v$$ver. This takes a few minutes."; \
	  nix build .#iso; \
	  sha256sum result/iso/NixRiot.iso | sed 's| result/iso/|  |' > SHA256SUMS; \
	  notes() { \
	    awk -v h="## $$ver" '$$0 == h { f = 1; next } /^## / { f = 0 } f' $(CHANGELOG); \
	  }; \
	  echo; \
	  echo "About to publish v$$ver to github.com/CyphrRiot/NixRiot:"; \
	  echo "  result/iso/NixRiot.iso  ($$(du -h result/iso/NixRiot.iso | cut -f1))"; \
	  echo "  SHA256SUMS"; \
	  echo; \
	  stale=$$(gh release list --limit 200 --json tagName -q '.[].tagName' | sort -V | head -n -1 || true); \
	  if [ -n "$$stale" ]; then \
	    echo "Old releases that will be deleted (the newest is kept):"; \
	    echo "$$stale" | sed 's/^/  /'; \
	    echo; \
	  fi; \
	  read -r -p "Push main and the tag, create the release, and delete the old ones? [Y/n] " answer; \
	  case "$$answer" in n|N) echo "Nothing published. Re-run 'make publish' when ready."; exit 0 ;; *) ;; esac; \
	  git push origin main; \
	  git push origin "v$$ver"; \
	  if gh release view "v$$ver" >/dev/null 2>&1; then \
	    gh release upload "v$$ver" result/iso/NixRiot.iso SHA256SUMS --clobber; \
	    gh release edit "v$$ver" --title "NixRiot v$$ver" --notes-file <(notes); \
	  else \
	    gh release create "v$$ver" --title "NixRiot v$$ver" --notes-file <(notes) \
	      result/iso/NixRiot.iso SHA256SUMS; \
	  fi; \
	  gh release edit "v$$ver" --draft=false >/dev/null; \
	  for f in NixRiot.iso SHA256SUMS; do \
	    gh release view "v$$ver" --json assets --jq '.assets[].name' | rg -qx "$$f" || { \
	      echo "v$$ver is missing $$f, or is still a draft."; \
	      exit 1; \
	    }; \
	  done; \
	  echo "Published v$$ver."; \
	  if [ -n "$$stale" ]; then \
	    echo "$$stale" | while read -r old; do gh release delete "$$old" --yes; done; \
	  fi
