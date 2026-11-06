#!/bin/bash
#
# Which channel this checkout builds and publishes.
#
# This is the only file in the repository that knows about branch names. The
# Justfile reads it as `default_tag`, so `just build`, `just ostree-rechunk`,
# `just generate-default-tag` and the workflows all agree with it, and
# `just build` passes it to the Containerfile as the BASE_TAG build argument to
# pick the base image. Every branch-dependent decision therefore comes from this
# one answer, which is what lets the branches carry identical files:
#
#   main     -> latest    builds on ghcr.io/zhchmmx/pixel-blue:latest
#   testing  -> testing   builds on ghcr.io/zhchmmx/pixel-blue:testing
#
# CI reads the branch from the GitHub environment, because actions/checkout
# leaves the checkout in detached HEAD state. A local checkout uses the branch
# it is on and falls back to latest, so feature branches still build.

set -euo pipefail

ref="${GITHUB_BASE_REF:-${GITHUB_REF_NAME:-}}"
if [[ -z "${ref}" ]]; then
  ref="$(git branch --show-current 2>/dev/null || true)"
fi

case "${ref}" in
  main)
    echo latest
    ;;
  testing)
    echo testing
    ;;
  *)
    # Never guess in CI: a workflow_dispatch on some unrelated branch has to fail
    # here, instead of publishing over the latest channel.
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
      echo "not a channel branch: '${ref:-detached HEAD}' (expected main or testing)" >&2
      exit 1
    fi
    echo latest
    ;;
esac
