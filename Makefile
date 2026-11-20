SHELL := bash

.PHONY: check build iso switch update fmt bump release release-major do-release publish

VERSION_FILE = VERSION
CHANGELOG = CHANGELOG.md
EDITOR ?= hx
# bump leaves the version untagged on purpose: 'make release' then releases it as
# it stands, so the ISO follows the update instead of racing it.
TAG ?= 1

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

# Bump the version and commit it, so installed machines see the update, without
# building or tagging anything. 'make release' later releases that same version.
bump:
	@$(MAKE) --no-print-directory do-release BUMP=minor TAG=0

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
	    if gh auth status >/dev/null 2>&1 && ! gh release view "v$$old" >/dev/null 2>&1; then \
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
	    if [ "$(TAG)" = 1 ]; then echo "Releasing $$old -> $$new"; else echo "Bumping $$old -> $$new"; fi; \
	    awk -v new="## $$new" \
	      '/^## Unreleased/ { print "## Unreleased"; print ""; print new; next } { print }' \
	      $(CHANGELOG) > $(CHANGELOG).tmp; \
	    mv $(CHANGELOG).tmp $(CHANGELOG); \
	    printf '%s\n' "$$new" > $(VERSION_FILE); \
	  fi; \
	  sed -i "s|badge/version-[0-9.]*-|badge/version-$$new-|" README.md; \
	  if [ "$(TAG)" = 1 ]; then msg="Release $$new"; else msg="Version $$new"; fi; \
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
	  if [ "$(TAG)" = 1 ]; then \
	    git tag -a "v$$new" -m "NixRiot v$$new"; \
	    echo "Tagged v$$new."; \
	    $(MAKE) --no-print-directory do-publish; \
	  else \
	    echo "VERSION is $$new and untagged. 'make release' will release it as it stands."; \
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
	  read -r -p "Push main and the tag, and create the release? [Y/n] " answer; \
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
	  echo "Published v$$ver."
