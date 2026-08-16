# ps-git-prompt

A git-aware, width-adaptive PowerShell 7 prompt.

This is a **PowerShell port of [bash-git-prompt-hook]** by BlueWizardHat - the original is the richer, more
battle-tested project, and this port exists purely to bring the same idea to PowerShell 7 on Windows. If you're on
Bash/Linux/macOS, use the original instead.

This port was forked from bash-git-prompt-hook at commit [`3cb185f2`] (2026-05-01). That commit is the baseline to diff
against when checking whether the original has gained features worth porting over.

## What it does

A single `prompt` function that shows, alongside the usual exit code / elapsed-time / cwd / user@host information:

- the current branch, or tag (annotated `✔`/non-annotated `✘`) if HEAD is on one, or the short commit hash if detached
- whether the branch has no upstream configured at all (shown in a different color) or is tracking a remote branch under
  a different name than expected (`← origin/other-branch`)
- an in-progress rebase / merge / cherry-pick / bisect, if any
- the abbreviated commit hash
- how many files are modified/staged/untracked (`≠N`)
- how far ahead/behind the upstream branch you are (`↑N ↓N`)
- how many stashes you have (`ᐅN`)
- the remote origin URL

It automatically drops the least useful pieces of that, in order, whenever your terminal is too narrow to show
everything on one line - see [Dropping information intelligently](#dropping-information-intelligently) below.

Requires PowerShell 7+ and `git` on `PATH`. No other dependencies - everything else uses raw ANSI escape sequences and
.NET/PowerShell built-ins, so there's nothing to install beyond a plain Windows + PowerShell 7 setup.

## Installation

```powershell
.\Scripts\Install.ps1
```

This does **not** copy any files anywhere - the module is imported straight from wherever you cloned this repo, so a
later `git pull` here picks up updates automatically. It appends a small marker-delimited block to your PowerShell
profile (`$PROFILE.CurrentUserAllHosts`, so it applies to `pwsh` console windows, Windows Terminal, and VS Code's
integrated terminal alike) that dot-sources `Scripts\ProfileSnippet.ps1`, then opens that file for you to
review/customize. Running the installer again is safe - it detects it's already installed and does nothing.

To remove it: `.\Scripts\Uninstall.ps1`.

### Configuring afterwards

`Scripts\ProfileSnippet.ps1` is the one file you're meant to hand-edit - it's what actually runs every time you open a
shell. It just imports the module, optionally overrides some settings, and calls `Install-GitPromptFunction`. You can
also change settings interactively at any time without editing anything, since they're read fresh on every prompt draw:

```powershell
$GitPromptSettings.ShowSha = $false
```

| Setting           | Default  | Description                                                                  |
|-------------------|----------|------------------------------------------------------------------------------|
| `ShowOrigin`      | `$true`  | Show the remote origin URL.                                                  |
| `ShowSha`         | `$true`  | Show the abbreviated commit hash.                                            |
| `ShowStashes`     | `$true`  | Show the stash count.                                                        |
| `ShowTracking`    | `$true`  | Show `← upstream` when the upstream isn't `origin/<branch>`.                 |
| `UseAsciiMarkers` | `$false` | Swap `→ ≠ ↑ ↓ ᐅ ✔ ✘` for plain ASCII (`M:`, `[ahead N]`, `stashes:`, `<-`).  |
| `InlineMode`      | `$true`  | Two-line layout (git info inline) vs. three-line (git info on its own line). |

## The smart prompt

Two-line, inline mode (the default) - git info sits at the end of line 1, after the directory:

```text
┌ ~/Projects/ps-git-prompt  →  master|c24d92f ≠7 ↑1 ↓2 ᐅ3  →  git@github.com:you/ps-git-prompt.git
└ you@host$
```

Three-line mode (`$GitPromptSettings.InlineMode = $false`), or automatically whenever the inline line doesn't fit even
after fully degrading (see below) - git info gets its own top line instead:

```text
┌ git@github.com:you/ps-git-prompt.git master|c24d92f ≠7 ↑1 ↓2 ᐅ3
│ ~/Projects/ps-git-prompt
└ you@host$
```

Outside a git repository, the git line disappears entirely:

```text
┌ ~/some/other/folder
└ you@host$
```

The line-marker (`┌│└`), exit code, and user/host are colored the same way as the original: red/failing vs.
blue/succeeding for the line markers; red for an elevated (Administrator) session, yellow for an SSH session, green
otherwise. The window title also updates to `user@host: cwd` on every prompt.

## Standalone usage

If you just want the git segment on its own - to embed in your own prompt function, for example - skip
`Install-GitPromptFunction` and call the two building blocks directly:

```powershell
Write-GitPromptStandalone            # prints "| ... |" for the current directory
Get-GitPromptStatus -Path <path>     # returns the underlying data/text without printing anything
```

```text
| git@github.com:you/ps-git-prompt.git master|c24d92f ≠7 ↑1 ↓2 ᐅ3 |
```

With `$GitPromptSettings.UseAsciiMarkers = $true`:

```text
| git@github.com:you/ps-git-prompt.git master|c24d92f M:7 [ahead 1, behind 2] stashes:3 |
```

## Dropping information intelligently

In inline mode, before falling back to the three-line layout, the prompt tries progressively smaller renderings of the
git segment, in this fixed order, and uses the first one that fits your terminal width:

1. everything
2. drop the commit hash
3. also shorten the origin URL to just its last path segment (`git@github.com:you/repo.git` → `repo.git`)
4. drop the origin URL entirely
5. also drop the stash count
6. also drop the tracking-branch suffix (down to just branch + state + modified count + ahead/behind)
7. give up on inline entirely and fall back to the three-line layout

Branch name, modified count, and ahead/behind are never dropped - if even step 6 doesn't fit, the prompt switches to
three-line mode for that draw instead of truncating further.

## Optional: git aliases

Separately from the prompt itself, `Scripts\Install-GitAliases.ps1` ports the original's `install-git-aliases.sh` - a
set of `git config --global` aliases (`lg`, `lga`, `st`, `ci`, `br`, `co`, `df`, `dc`, `lol`, `lola`, `ls`, `ign`) and
some color settings. It isn't run automatically by `Install.ps1`, matching how the original keeps it separate too - run
it yourself if you want it:

```powershell
.\Scripts\Install-GitAliases.ps1
```

## Notes on this port

A handful of deliberate departures from the bash original, made in the interest of correctness, simplicity, or
Windows-appropriateness rather than pixel-for-pixel fidelity:

- **Git calls are batched.** The bash original shells out to `git` roughly 9 times per prompt draw; this port uses
  `git status --porcelain=v2 --branch` to gather branch/upstream/ahead-behind/ dirty-count in one call, cutting the
  typical case to about 3-4 process spawns. Windows process creation is considerably more expensive than Linux
  fork/exec, so this matters more here than it does in the original.
- **The command timer uses PowerShell's own `Get-History` timestamps** rather than replicating bash's manual
  `DEBUG`-trap/Stopwatch mechanism - simpler, and it avoids an edge case in the original where pressing Enter on a blank
  line can show a garbage elapsed time.
- **`ShowOrigin` consistently controls origin visibility in every mode.** In the bash original it only gated origin
  display in inline mode; separate-line mode always showed the origin regardless of the setting. That inconsistency
  wasn't replicated here.
- **The commit-hash separator is `|`** (e.g. `master|c24d92f`), matching the current `bash-git-prompt-hook.sh` source.
  The original repo's own screenshots show it in parentheses instead (`master (c24d92f)`) - those images predate a later
  change in the script and are stale relative to the code being ported here.

## Development

Everything lives under `Public\` (exported functions) and `Private\` (internal helpers) in the `PsGitPrompt` module. To
iterate:

```powershell
Import-Module .\PsGitPrompt.psd1 -Force
Install-GitPromptFunction
```

There's no bundled test suite - `pwsh` doesn't ship with Pester by default, and adding it as a hard dependency would go
against keeping this dependency-free for end users. Verify changes by importing the module and checking rendering
against a few repo states (clean/dirty, ahead/behind, detached HEAD, tags, an in-progress rebase, a non-git directory,
both marker modes, and a narrow terminal to exercise the degradation ladder).

## License

MIT - see [LICENSE](LICENSE). This project ports code from [bash-git-prompt-hook], also MIT licensed by BlueWizardHat;
its original license text is kept as [LICENSE-BlueWizardHat](LICENSE-BlueWizardHat).

[bash-git-prompt-hook]: https://github.com/BlueWizardHat/bash-git-prompt-hook
[`3cb185f2`]: https://github.com/BlueWizardHat/bash-git-prompt-hook/commit/3cb185f23ca31187df15547c17857a5bd83d0d3c
