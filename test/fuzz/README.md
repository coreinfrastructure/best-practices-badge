# Fuzz testing with OSS-Fuzz and Ruzzy

This directory contains the configuration files needed to add this project to
[Google OSS-Fuzz](https://github.com/google/oss-fuzz), Google's continuous
fuzzing service for open-source software.  The fuzz harnesses themselves live
in `script/fuzz_*.rb` so they are maintained alongside the rest of the project
code.

## Directory layout

```
test/fuzz/
  project.yaml   – OSS-Fuzz project metadata
  Dockerfile     – Derives from gcr.io/oss-fuzz-base/base-builder-ruby
  build.sh       – Installs gems, builds targets, packs seed corpora
  README.md      – This file

script/
  fuzz_url_validator.rb       – Fuzzes URL validation logic
  fuzz_markdown_processor.rb  – Fuzzes the markdown processing pipeline
```

## Fuzzer overview

The project uses [Ruzzy](https://github.com/trailofbits/ruzzy) (Trail of Bits),
a coverage-guided fuzzer for Ruby that wraps libFuzzer.  It is pre-installed in
the `base-builder-ruby` OSS-Fuzz base image.

### fuzz\_url\_validator

Targets `app/validators/url_validator.rb`.  The validator logic is inlined
(no Rails/ActiveModel required) to keep the harness simple.

Security properties checked:

- ReDoS via catastrophic backtracking in `URL_REGEX`
- Encoding attacks through malformed percent-encoded byte sequences
- Edge cases in the `unescape_unforced` → `force_encoding('UTF-8')` pipeline

### fuzz\_markdown\_processor

Targets `app/lib/markdown_processor.rb` and `app/lib/invoke_commonmarker.rb`.
The harness stubs the two ActiveSupport string extensions the module uses
(`html_safe`, `blank?`) so Rails does not need to be loaded.

Security properties checked:

- ReDoS in `MARKDOWN_UNNECESSARY` (complex possessive-quantifier regex)
- ReDoS in `PREFIXED_URL_REGEX`
- XSS bypass via the URL-protocol sanitization (`javascript:`, `data:`, etc.)
- Memory-safety bugs in the CommonMarker Rust/C extension surfaced through
  Ruby-level input

## Running locally with Ruzzy

Ruzzy requires clang to build its C extension.  Follow the full installation
instructions at <https://github.com/trailofbits/ruzzy> (set `CC`, `CXX`,
`LDSHARED`, and `LDSHAREDXX` to your clang binaries), then:

```bash
export ASAN_OPTIONS="allocator_may_return_null=1:detect_leaks=0:use_sigaltstack=0"
```

Run the URL-validation harness (requires activemodel):

```bash
gem install activemodel
mkdir -p tmp/corpus-url
LD_PRELOAD=$(ruby -e 'require "ruzzy"; print Ruzzy::ASAN_PATH') \
  ruby script/fuzz_url_validator.rb tmp/corpus-url
```

Run the markdown harness (install commonmarker first if not already installed):

```bash
gem install commonmarker
mkdir -p tmp/corpus-md
LD_PRELOAD=$(ruby -e 'require "ruzzy"; print Ruzzy::ASAN_PATH') \
  ruby script/fuzz_markdown_processor.rb tmp/corpus-md
```

## Testing with the OSS-Fuzz infrastructure locally

Requires Docker and a local checkout of
[google/oss-fuzz](https://github.com/google/oss-fuzz).
First copy the three files from `test/fuzz/` into
`projects/best-practices-badge/` inside that checkout (see "Submitting"
below), then from the root of the oss-fuzz checkout run:

```bash
python3 infra/helper.py build_image best-practices-badge
python3 infra/helper.py build_fuzzers --sanitizer address best-practices-badge
python3 infra/helper.py check_build best-practices-badge
python3 infra/helper.py run_fuzzer best-practices-badge fuzz_url_validator
python3 infra/helper.py run_fuzzer best-practices-badge fuzz_markdown_processor
```

## Submitting to OSS-Fuzz

1. Fork <https://github.com/google/oss-fuzz>.
2. Create `projects/best-practices-badge/` in your fork.
3. Copy `test/fuzz/project.yaml`, `test/fuzz/Dockerfile`, and
   `test/fuzz/build.sh` into that directory.
4. Verify `primary_contact` in `project.yaml` is a Google-account-linked
   address (required by OSS-Fuzz for ClusterFuzz dashboard access).
5. Open a pull request against `google/oss-fuzz` following the guidance at
   <https://google.github.io/oss-fuzz/getting-started/accepting-new-projects/>.

The `build.sh` references `script/fuzz_*.rb` via the git clone of this repo,
so the harnesses stay in sync automatically once the PR is merged.

## Adding a new fuzz target

1. Create `script/fuzz_<name>.rb` following the pattern of the existing
   harnesses (implement `test_one_input` as a lambda and call `Ruzzy.fuzz`).
2. Add a `ruzzy-build` line for the new file in `test/fuzz/build.sh`.
3. Optionally add seed corpus entries in the corresponding `mkdir`/`zip` block
   in `build.sh` to help the fuzzer find interesting paths faster.
4. Run locally to confirm it works before committing.
