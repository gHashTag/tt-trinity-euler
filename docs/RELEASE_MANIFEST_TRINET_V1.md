# Release Manifest — TRI-NET v1 (tt-trinity-euler, TTSKY26b)

**Document ID:** TRINITY-RELEASE-MANIFEST-V1
**Manifest version:** `v1.0.0-ttsky26b`
**Status:** PLANNED — this manifest describes the Zenodo bundle that
*will* accompany the TRI-1 Euler / TTSKY26b deposition **if and when** the
upload is performed. No DOI has been minted for this bundle yet.
**Last updated:** 2026-05-18
**Companion docs:** [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3
(Zenodo bundle readiness), [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md),
[`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md),
[`.zenodo.json`](../.zenodo.json)

> **R5-Honesty contract — anti-claim.**
> **No per-repo or per-shuttle Zenodo DOI has been minted for the TRI-1
> Euler TTSKY26b bundle.** The act of merging this manifest, or merging
> [`.zenodo.json`](../.zenodo.json), does NOT mint a DOI. The only DOI
> cited anywhere in this repo is the line-wide Trinity Stack provenance
> DOI [`10.5281/zenodo.19227877`](https://doi.org/10.5281/zenodo.19227877),
> which is published and external. Any TTSKY26b-specific DOI URL appearing
> anywhere in this repo before a Zenodo deposition is published is a
> bug; the spec gate
> ([`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh)
> step 4) refuses any non-canonical `10.5281/zenodo.*` reference under
> `docs/`. See claim `VCM-DOI-001` / `VCM-DOI-002` and anti-claim
> `NO-FAKE-DOI` in the [Verification Claims Matrix](VERIFICATION_CLAIMS_MATRIX.md).

---

## 1. Purpose

This manifest is the **single source of truth** for what the TRI-NET v1
TTSKY26b Zenodo deposition will contain, what metadata it will carry,
and what claims it MUST not make. The manifest is reviewed and merged
*before* a deposition is uploaded; the deposition then either matches
this manifest exactly, or the manifest is updated and the deposition is
re-uploaded.

This decouples the *plan* for a citable bundle from the *act* of
publishing one, which is what `NO-FAKE-DOI` requires.

---

## 2. Bundle identity

| Field | Value |
|---|---|
| Bundle title | TRI-1 Euler — Trinity TRI-NET e-engine (8x2 SUPER-CROWN + 10 CLARA gaps + D2D holo mesh) |
| Bundle version | `v1.0.0-ttsky26b` |
| Bundle date | 2026-05-18 (manifest); upload date TBD |
| Source commit | head of branch `feat/trinet-verification-hardening` at PR #14 merge time |
| Source URL | https://github.com/gHashTag/tt-trinity-euler |
| License | Apache-2.0 ([`LICENSE`](../LICENSE)) |
| Upload-type (Zenodo) | software |
| Resource-type | RTL + verification evidence + spec |

---

## 3. Creators and affiliations (inferable from repo)

Per [`info.yaml`](../info.yaml) `project.author`:

| Name | Affiliation | Source |
|---|---|---|
| Vasilev, Dmitrii | Trinity Stack | `info.yaml` |

> If additional creators are added before a future deposition, they MUST
> be added to **both** `.zenodo.json` and this row, with a written
> attribution audit trail in `CHANGELOG.md`.

---

## 4. Related identifiers (placeholders + concrete)

| Relation | Identifier | Resource type | Status |
|---|---|---|---|
| isPartOf | `10.5281/zenodo.19227877` (Trinity Stack line-wide DOI) | software | **PUBLISHED** (external) |
| isSupplementTo | https://github.com/gHashTag/tt-trinity-euler | software | concrete |
| isCompiledBy | https://github.com/gHashTag/t27 | software | concrete |
| references | https://github.com/gHashTag/tt-trinity-phi | software | concrete |
| references | https://github.com/gHashTag/tt-trinity-gamma | software | concrete |
| references | https://app.tinytapeout.com/shuttles/ttsky26b | publication-other | concrete |
| cites | arXiv:2402.17764 (BitNet b1.58) | publication-article | concrete |
| cites | arXiv:2310.10537 (MX block-FP) | publication-article | concrete |
| isVersionOf | _(placeholder)_ TTSKY26b shuttle Zenodo DOI | software | **PLANNED — not minted** |
| isDocumentedBy | _(placeholder)_ Trinity TRI-NET whitepaper Zenodo DOI | publication-article | **PLANNED — not minted** |

The two placeholder rows above are explicitly listed so that future
edits don't accidentally invent identifiers; they MUST stay as text
"PLANNED — not minted" until a Zenodo record exists.

---

## 5. Files / artefacts the bundle SHOULD contain

The bundle is a tarball of the source tree at the named commit plus a
small number of derived artefacts. The list below names each file
*relative to the repo root* so a reproducer can match the manifest to
the tarball entries.

### 5.1 Frozen RTL + project metadata

| Path | Purpose |
|---|---|
| `src/**` | All 86+ synthesisable Verilog-2005 modules |
| `info.yaml` | Tiny Tapeout shuttle metadata + module list |
| `LICENSE` | Apache-2.0 |
| `README.md` | Repo entry doc |
| `CHANGELOG.md` | Version history |

### 5.2 Specs and verification evidence

| Path | Purpose |
|---|---|
| [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md) | Single index of every numerical claim |
| [`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md) | RBB → FBB → CAP_BOOST → IDLE FSM |
| [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) | Per-deck readiness |
| [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) | Die-to-die packet protocol draft |
| [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) | NMSE comparison protocol |
| [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) | 22FDX TOPS/W projection |
| [`docs/ARCHITECTURE_QUICK_WINS.md`](ARCHITECTURE_QUICK_WINS.md) | Competitor-informed quick wins |
| [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](SCIENTIFIC_IMPROVEMENT_PLAN.md) | 2026 SIP — target / projection / VERIFY tracks |
| [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json) | GoldenFloat format family + GF16 schema |
| [`conformance/D2D-CONFORMANCE-V0.json`](../conformance/D2D-CONFORMANCE-V0.json) | D2D v0.1 conformance spec |
| `conformance/d2d/d2d_tc_001..006.json` | D2D test cases |
| [`tests/vectors/nmse/gf16_vs_bfloat16_v0.json`](../tests/vectors/nmse/gf16_vs_bfloat16_v0.json) | NMSE golden vector pack |
| [`tests/vectors/nmse/schema.json`](../tests/vectors/nmse/schema.json) | Vector-pack + result schema |

### 5.3 CI gate + tooling

| Path | Purpose |
|---|---|
| [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh) | Spec/claims CI gate |
| `.github/workflows/tri-test.yml` | Wires the gate into CI |
| `assertions/`, `coq/`, `trios-coq/` | Formal artefacts |

### 5.4 Logs SHOULD also be re-attached at upload time

Not in the source tree today; required at upload time:

| Path | Source | Promotes |
|---|---|---|
| `sim/logs/tb_gf16_dot8.log` | `sim/tb_gf16_dot8.v` PASS counter (`TOTAL PASS=17 FAIL=0`) | `VCM-GF16-002` |
| `boards/openlane2/<commit>/WNS_TNS_DRC_LVS.json` | OpenLane2 sign-off | promotes `RTL → SYNTH` rows |
| `boards/fpga/XC7A100T_<commit>.log` | FPGA Fmax run | resolves `VCM-FPGA-001` |

These three logs are explicitly NOT in this branch (the matrix rows
remain `SIM` / `unverified-in-this-branch`). The deposition MUST NOT be
uploaded without them, or the corresponding claims must be re-labelled
in the matrix before upload.

---

## 6. Hashes (manifest-time SHA-256)

These are SHA-256 hashes of the **key new artefacts** at the manifest
commit. They are NOT a substitute for the final tarball checksum that
Zenodo computes; they are a tamper-evident snapshot so the deposition
content can be checked against the merge commit.

| File | SHA-256 (manifest commit) |
|---|---|
| `docs/VERIFICATION_CLAIMS_MATRIX.md`    | `bd64444c178ba33a3c88091c6e58fbadba127333e3ad8ffcbd12830f3e6643f7` |
| `docs/TRIPLE_DECK_STATE_MACHINE.md`     | `750cfac3ad83346a2f6d60f3d1995f07c0bd5880c6c1c79880309039bdeec4ea` |
| `docs/ARCHITECTURE_QUICK_WINS.md`       | `5f800ba5dff7015957dbf5ab8a9b7f7ebe9fee021abc4294cb770317e01f804a` |
| `docs/D2D_PROTOCOL.md`                  | `302ef06158756038bfe89992e5b93f21c22cd4498ec67e1b5322c904dd7838a4` |
| `docs/GF16_BFLOAT16_NMSE.md`            | `fb2045c59db9a83dc80dda4fe62c78b79b9b41a735fe1715b07fd463766b1b9c` |
| `docs/PROJECTIONS_22FDX.md`             | `4008f0adebf71c12b120dae41a522c1c6c84722832e7a07f21aca80f0d4a937c` |
| `docs/TRIPLE_DECK_STATUS.md`            | `82d97960b26fcd2052e29f08c6aa8b06da9914357810459a47885acd7e114503` |
| `conformance/D2D-CONFORMANCE-V0.json`   | `3c9c50b26043c56edaa6d912c1deda6f07948b982fa9cbf51264f89234245032` |
| `conformance/FORMAT-SPEC-001.json`      | `149094e8959c9727ec2edfb39440f7584c5af2bf00f8230dd91a8019370873ab` |
| `tests/vectors/nmse/gf16_vs_bfloat16_v0.json` | `e845a15c2ec1c00f66cf675b6d9bb99fdd71a77fc47ccf67fc0152b6a2654102` |
| `tests/vectors/nmse/schema.json`        | `53976b6bf704db265884d5f32740236cf7e55384627ff918a612b7c375c083b7` |
| `scripts/check_trinet_specs.sh`         | `5c7ba232ad8d16ef1330a3d6d57024f078f0c303c602c3b9ed5bbfd5af826711` |
| `.zenodo.json`                          | `a44fd3059d0fffdeb4cf1d0f53f9a01046ac11a2af0c4e632b2e6a644510a112` |
| `info.yaml`                             | `c618619c6c00b7c2bf8df5b732d4fc2217dba936d49d3ebd7bb083fe312878d3` |

Reproduce with `sha256sum` from the repo root at the merge commit of PR
#14.

> **Anti-claim:** these hashes describe **manifest-time** state. They are
> NOT a substitute for the Zenodo file checksum that the platform itself
> computes on deposit. Drift between the two MUST be reported in
> `CHANGELOG.md` before the deposition is published.

---

## 7. What the bundle MUST NOT contain

Re-stated from [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.3
and now lifted to the deposition layer:

- Any quoted silicon TOPS/W number that is not in the `MEASURED` tier.
- Any "DARPA-CLARA award / contract" implication — alignment only, per
  `VCM-FUND-001` and anti-claim `NO-FUNDING`.
- Any FPGA Fmax claim that is not backed by a re-attached log under
  `boards/` (the "323 MHz on XC7A100T" line is currently
  `unverified-in-this-branch` per [BENCHMARKS.md §3](../BENCHMARKS.md)
  and `VCM-FPGA-001`).
- Any NMSE *number* — only the protocol and the seeded vector pack.
- Any TTSKY26b-specific DOI URL until the Zenodo deposition is actually
  published.

---

## 8. Pre-upload checklist

When (and only when) a Zenodo deposition is being uploaded for this
bundle, the uploader MUST verify each of the following:

- [ ] `scripts/check_trinet_specs.sh` exits 0 on the merge commit.
- [ ] Each file in §5.1 and §5.2 is present in the tarball and has the
      SHA-256 listed in §6 (or §6 has been updated and re-merged).
- [ ] The Zenodo record's metadata matches `.zenodo.json` field-by-field
      (title, version, creators, license, keywords, related identifiers,
      notes).
- [ ] The Zenodo record carries the §7 anti-claim list in the public
      "Notes" / description block.
- [ ] After upload, the DOI that Zenodo mints is added to **both**
      [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.1 and the
      `isVersionOf` row in §4 above, and the
      `VCM-DOI-002` row in the matrix is promoted from `PLANNED` to
      `PUBLISHED`.
- [ ] The first commit citing the new DOI updates this manifest's
      `isVersionOf` placeholder to the concrete DOI string and bumps
      the `Manifest version` field in §0.

Until every item is checked, no public material may cite a TTSKY26b
DOI URL.

---

## 9. Update policy

1. This manifest is updated **before** a Zenodo deposition is published,
   not after.
2. Hashes in §6 are recomputed at every merge that touches a listed
   file.
3. The `Anti-claim` block in §7 is non-negotiable. Removing a bullet
   from §7 requires evidence (a published Zenodo record, a silicon
   measurement, a returned FPGA log, etc.) in the same PR.
4. Manifest version (top of file) bumps when §2 or §5 changes
   semantically.

---

## 10. Links

- [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3 — Zenodo bundle
  readiness (target state)
- [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md) —
  claim `VCM-DOI-001` (canonical line-wide DOI) + `VCM-DOI-002`
  (no per-shuttle DOI minted) + anti-claim `NO-FAKE-DOI`
- [`.zenodo.json`](../.zenodo.json) — the metadata that will accompany
  a future deposition
- [`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md) — external
  publication / DOI / programme link index
- Trinity Stack line-wide DOI (the only published one):
  https://doi.org/10.5281/zenodo.19227877
