#!/usr/bin/env bash
#
# niori-texi2pdf.sh
#
# Build a PDF from a Texinfo manual (e.g. niori.texi) using YOUR preferred
# fonts, via the Texinfo "LaTeX backend".
#
# Why not plain "texi2pdf"?
#   texi2pdf always runs pdftex with texinfo.tex, and Texinfo has no command
#   to switch the font family, nor an engine selector — so fonts are fixed to
#   Computer Modern on that route. Instead, this script:
#     1. runs  texi2any --latex            (needs GNU Texinfo >= 7.0)
#        to turn the .texi into a plain LaTeX .tex file;
#     2. injects a fontspec block into the preamble and removes the legacy
#        inputenc/fontenc lines (pdflatex-only, they fight fontspec under
#        XeLaTeX/LuaLaTeX);
#     3. compiles with latexmk + xelatex (or lualatex). Indices (@printindex)
#        are handled automatically — the generated file uses imakeidx, and
#        latexmk runs makeindex between passes as needed.
#
# Default fonts (mode FONT_MODE=texlive: the OpenType files shipped by these
# TeX Live packages are loaded by FILENAME via kpathsea, so they do NOT need
# to be installed system-wide):
#   body text ........ Erewhon (Regular)      package: erewhon
#   headings ......... IBM Plex Mono (Medium) package: plex
#   sans (@sansserif)  IBM Plex Sans (Medium) package: plex
#   code/mono ........ Inconsolata (zi4)      package: inconsolata
#
# Index note: the generated file starts a new page before EVERY @printindex
# list — and because the book class is two-sided, imakeidx's default
# \cleardoublepage jumps to the next ODD page, so with four indices you get
# one page holding only the word "Index" plus a fully blank page between
# each pair of index lists (this manual: 9 pages of index, ~5 of them empty).
# By default this script rewrites the imakeidx setup so that all indices
# flow continuously in two columns under the single "Index" chapter, each
# with its own subheading (Key/Variable/Function/Concept Index). On this
# manual that saves ~6 pages. Restore the original layout with:
#   INDEX_COMPACT=0 ./niori-texi2pdf.sh niori.texi
#
# Heading typography: the LaTeX backend emits plain book-class sectioning
# (\chapter/\section/...), which by default typesets headings in the MAIN
# serif font (bold) — the sans family is NOT used for headings. To put
# IBM Plex Mono on every heading, this script patches the class's heading
# macros (etoolbox \patchcmd; deliberately NO titlesec — it conflicts with
# the generated document) and inserts \NioriHeadingFont (IBM Plex Mono)
# into chapter/part heads, all \@startsection levels, the title-page
# heading and the titleps running heads. Patch failures degrade to a
# build-time warning instead of breaking the compile.
#
# Code blocks: the backend typesets @example/@lisp/... in a custom
# Texinfopreformatted environment. When CODE_BOX=1 (default) the script
# wraps it in a page-breakable "framed" box filled with NioriCodeBackground
# and edged in NioriCodeRule (the two palette colors below).
#
# NEW: Tables: when the backend emits a \headitem row (@multitable) or a
# description-style table (@table/@ftable/@vtable), this script patches
# \headitem and \descriptionlabel so the header/term is typeset in
# NioriTableHeaderFg and bold, and installs a light \rowcolors pattern
# (NioriTableStripe) on every tabular/longtable body. Both are silent
# no-ops when the backend does not produce them. Override the two
# colours with:
#   TABLE_HEADER_COLOR=1A3A5C TABLE_STRIPE_COLOR=F0F5FA ./niori-texi2pdf.sh niori.texi
#
# Usage:
#   ./niori-texi2pdf.sh [file.texi]          (default file: niori.texi)
#
#   Preview the LaTeX font block without compiling anything:
#   PRINT_BLOCK=1 ./niori-texi2pdf.sh niori.texi
#
#   Switch to fonts installed system-wide (fc-list must see them):
#   FONT_MODE=fontspec ./niori-texi2pdf.sh niori.texi
#
#   Other overrides:
#   PAPER=letterpaper ENGINE=lualatex KEEP_LATEX=1 ./niori-texi2pdf.sh niori.texi
#   INNER_MARGIN=23mm OUTER_MARGIN=20mm ./niori-texi2pdf.sh niori.texi
#   HEADING_COLOR=2457A7 ACCENT_COLOR=008C95 ./niori-texi2pdf.sh niori.texi
#   ACCENT_COLOR=00828B ./niori-texi2pdf.sh niori.texi   (teal that meets 4.5:1)
#   CODE_BOX=0 ./niori-texi2pdf.sh niori.texi   (plain, unboxed code blocks;
#             keeps the NioriCodeBackground/NioriCodeRule colors defined only)
#   INDEX_COMPACT=0 ./niori-texi2pdf.sh niori.texi   (original index page breaks)
#   TABLE_HEADER_COLOR=1A3A5C TABLE_STRIPE_COLOR=F0F5FA ./niori-texi2pdf.sh niori.texi
#             (bold coloured table headers + light zebra stripes)
#
# Equivalent manual 3-step recipe (XeLaTeX + fontspec):
#   texi2any --latex -o niori.tex niori.texi
#     # in niori.tex preamble: DELETE \usepackage[utf8]{inputenc} and
#     # \usepackage[T1]{fontenc}, then ADD right after \documentclass{book}:
#     #   \usepackage{fontspec}
#     #   \setmainfont{Erewhon-Regular.otf}[ BoldFont = Erewhon-Bold.otf,
#     #     ItalicFont = Erewhon-Italic.otf,
#     #     BoldItalicFont = Erewhon-BoldItalic.otf ]
#     #   \newfontfamily\NioriHeadingFont{IBMPlexMono-Medium.otf}[
#     #     BoldFont = IBMPlexMono-Bold.otf,
#     #     ItalicFont = IBMPlexMono-MediumItalic.otf,
#     #     BoldItalicFont = IBMPlexMono-BoldItalic.otf ]
#     #   \setsansfont{IBMPlexSans-Medium.otf}[ BoldFont = IBMPlexSans-Bold.otf,
#     #     ItalicFont = IBMPlexSans-MediumItalic.otf,
#     #     BoldItalicFont = IBMPlexSans-BoldItalic.otf ]
#     #   \setmonofont{Inconsolatazi4-Regular.otf}[ BoldFont = Inconsolatazi4-Bold.otf,
#     #     Scale = MatchLowercase ]
#     #   plus \usepackage{framed} and the heading/code-box/table \AtBeginDocument
#     #   block — copy it verbatim from FONTBLOCK in this script
#   latexmk -xelatex -interaction=nonstopmode niori.tex
#
# Requirements:
#   * GNU Texinfo >= 7.0 for `texi2any --latex` (7.1+ recommended).
#       Debian/Ubuntu:  sudo apt install texinfo texlive-xetex latexmk
#                       texlive-fonts-extra   (erewhon, plex, inconsolata)
#                       (Ubuntu 22.04 ships texinfo 6.8 — too old; build a
#                        newer one from source, see TEXINFO_FROM_SOURCE below)
#       Fedora:         sudo dnf install texinfo texlive-xetex latexmk
#                       texlive-erewhon texlive-plex texlive-inconsolata
#                       texlive-framed
#       macOS:          brew install texinfo && export PATH="$(brew --prefix texinfo)/bin:$PATH"
#                       plus MacTeX (BasicTeX: sudo tlmgr install erewhon
#                       plex inconsolata latexmk framed)
#       Windows:        use WSL; MiKTeX alone does not ship texi2any.
#   * In texlive mode the fonts come from the packages above; in fontspec
#     mode the three families must be installed system-wide.
#   * Inconsolata has no italic/bold-italic design upstream — bold italic
#     code will be substituted by bold; everything else is covered.
#
# If texi2any is too old and you cannot get a distro upgrade:
#   TEXINFO_FROM_SOURCE:  curl -O https://ftp.gnu.org/gnu/texinfo/texinfo-7.3.tar.xz
#                         tar xf texinfo-7.3.tar.xz && cd texinfo-7.3
#                         ./configure --prefix="$HOME/.local" && make && make install
#                         export PATH="$HOME/.local/bin:$PATH"

set -euo pipefail

# ============================================================ USER SETTINGS
FONT_MODE="${FONT_MODE:-texlive}"   # texlive | fontspec (system-wide)

# --- texlive mode: OTF files shipped in TeX Live packages -------------------
MAIN_UP="${MAIN_UP:-Erewhon-Regular.otf}"
MAIN_BOLD="${MAIN_BOLD:-Erewhon-Bold.otf}"
MAIN_ITALIC="${MAIN_ITALIC:-Erewhon-Italic.otf}"
MAIN_BOLDITALIC="${MAIN_BOLDITALIC:-Erewhon-BoldItalic.otf}"
# --- headings: IBM Plex Mono (patched into the class heading macros) --------
HEADING_UP="${HEADING_UP:-IBMPlexMono-Medium.otf}"       # Medium upright — heading weight
HEADING_BOLD="${HEADING_BOLD:-IBMPlexMono-Bold.otf}"     # bold headings = full Bold
HEADING_ITALIC="${HEADING_ITALIC:-IBMPlexMono-MediumItalic.otf}"
HEADING_BOLDITALIC="${HEADING_BOLDITALIC:-IBMPlexMono-BoldItalic.otf}"

# --- sans family (only @sansserif in body text reaches it) ------------------
SANS_UP="${SANS_UP:-IBMPlexSans-Medium.otf}"
SANS_BOLD="${SANS_BOLD:-IBMPlexSans-Bold.otf}"
SANS_ITALIC="${SANS_ITALIC:-IBMPlexSans-MediumItalic.otf}"
SANS_BOLDITALIC="${SANS_BOLDITALIC:-IBMPlexSans-BoldItalic.otf}"
MONO_UP="${MONO_UP:-Inconsolatazi4-Regular.otf}"     # zi4 = the package's tuned cut
MONO_BOLD="${MONO_BOLD:-Inconsolatazi4-Bold.otf}"    # (slashed zero, upright quotes)

# --- fontspec mode: families installed system-wide --------------------------
MAIN_FONT="${MAIN_FONT:-Erewhon}"
HEADING_FONT="${HEADING_FONT:-IBM Plex Mono}"
SANS_FONT="${SANS_FONT:-IBM Plex Sans}"
MONO_FONT="${MONO_FONT:-Inconsolata}"

# --- page layout and visual style --------------------------------------------
PAPER="${PAPER:-a4paper}"
INNER_MARGIN="${INNER_MARGIN:-21mm}"
OUTER_MARGIN="${OUTER_MARGIN:-19mm}"
TOP_MARGIN="${TOP_MARGIN:-22mm}"
BOTTOM_MARGIN="${BOTTOM_MARGIN:-23mm}"
HEAD_HEIGHT="${HEAD_HEIGHT:-14pt}"

# Niori palette; values are HTML hex without '#'. Measured contrast on white
# (WCAG 2.x): TEXT 13.2:1 (AAA) | HEADING 7.0:1 (AAA, barely) | ACCENT 4.05:1
# — passes the 3:1 large-text and non-text rules but is below the 4.5:1
# normal-text AA rule, so body-size external links are not strict-AA; use
# ACCENT_COLOR=00828B (same hue, just darker, 4.6:1) if you need that.
# CODE_BACKGROUND/CODE_RULE paint the preformatted code blocks when
# CODE_BOX=1; with CODE_BOX=0 they stay defined but unused. The border is
# decorative: #B8D2EC is only ~1.4:1 against the code background, which is
# fine as long as the box is not the sole means of identifying code; set
# CODE_RULE=5B8FCB if the border itself must pass the 3:1 non-text rule.
TEXT_COLOR="${TEXT_COLOR:-26313D}"
HEADING_COLOR="${HEADING_COLOR:-214F98}"
ACCENT_COLOR="${ACCENT_COLOR:-005C62}"
CODE_BACKGROUND="${CODE_BACKGROUND:-EEF5FC}"
CODE_RULE="${CODE_RULE:-7D8FA0}"

# NEW: --- table styling ------------------------------------------------------
# Header/term text of every table is recoloured to TABLE_HEADER_COLOR (default
# a dark navy).  Body rows get an alternating stripe painted in
# TABLE_STRIPE_COLOR (a very light blue-grey; decorative, so it is below the
# 3:1 non-text rule — set something like DCE9F5 if the stripe itself must pass).
TABLE_HEADER_COLOR="${TABLE_HEADER_COLOR:-1A3A5C}"
TABLE_STRIPE_COLOR="${TABLE_STRIPE_COLOR:-F0F5FA}"

# Wrap Texinfo preformatted (code) blocks in a page-breakable box filled
# with NioriCodeBackground and edged in NioriCodeRule ("framed" package).
CODE_BOX="${CODE_BOX:-1}"

# --- extras (both modes) -----------------------------------------------------
MAIN_OPTS="${MAIN_OPTS:-}"
HEADING_OPTS="${HEADING_OPTS:-Scale=MatchLowercase}"
SANS_OPTS="${SANS_OPTS:-Scale=MatchLowercase}"
MONO_OPTS="${MONO_OPTS:-Scale=MatchLowercase}"
FONT_FEATURES="${FONT_FEATURES:-}"
INDEX_COMPACT="${INDEX_COMPACT:-1}"
ENGINE="${ENGINE:-xelatex}"
SHELL_ESCAPE="${SHELL_ESCAPE:-1}"
EXTRA_PREAMBLE="${EXTRA_PREAMBLE:-}"
KEEP_LATEX="${KEEP_LATEX:-1}"
PRINT_BLOCK="${PRINT_BLOCK:-0}"

# ============================================================ end settings

SRC="${1:-niori.texi}"
[ -f "$SRC" ] || { echo "ERROR: no such file: $SRC" >&2; exit 1; }
JOB="$(basename "${SRC%.texi}")"

say()  { printf '%s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { say "ERROR: '$1' not found. $2"; exit 1; }; }

# --- font block builders ----------------------------------------------------
# family_spec <cmd> <upright.otf> <bold.otf> <italic.otf|-> <bolditalic.otf|-> <extra-opts>
family_spec() {
    local cmd="$1" up="$2" bold="$3" ital="$4" bi="$5" opts="$6"
    local out="\\${cmd}{$up}[ BoldFont = ${bold}"
    if [ "$ital" != "-" ]; then out="$out, ItalicFont = ${ital}"; fi
    if [ "$bi"   != "-" ]; then out="$out, BoldItalicFont = ${bi}"; fi
    if [ -n "$opts" ];     then out="$out, ${opts}"; fi
    printf '%s' "$out ]"
}

# named_family <cmd> <family-name> <extra-opts>
named_family() {
    if [ -n "$3" ]; then printf '%s' "\\$1{$2}[ $3 ]"
    else printf '%s' "\\$1{$2}"; fi
}

if [ "$FONT_MODE" = "texlive" ]; then
    MAIN_SPEC="$(family_spec setmainfont  "$MAIN_UP"  "$MAIN_BOLD"  "$MAIN_ITALIC"  "$MAIN_BOLDITALIC"  "$MAIN_OPTS")"
    HEADING_SPEC="$(family_spec 'newfontfamily\NioriHeadingFont' "$HEADING_UP" "$HEADING_BOLD" "$HEADING_ITALIC" "$HEADING_BOLDITALIC" "$HEADING_OPTS")"
    SANS_SPEC="$(family_spec setsansfont  "$SANS_UP"  "$SANS_BOLD"  "$SANS_ITALIC"  "$SANS_BOLDITALIC"  "$SANS_OPTS")"
    MONO_SPEC="$(family_spec setmonofont  "$MONO_UP"  "$MONO_BOLD"  "-"             "-"                 "$MONO_OPTS")"
elif [ "$FONT_MODE" = "fontspec" ]; then
    MAIN_SPEC="$(named_family setmainfont "$MAIN_FONT" "$MAIN_OPTS")"
    HEADING_SPEC="$(named_family 'newfontfamily\NioriHeadingFont' "$HEADING_FONT" "$HEADING_OPTS")"
    SANS_SPEC="$(named_family setsansfont "$SANS_FONT" "$SANS_OPTS")"
    MONO_SPEC="$(named_family setmonofont "$MONO_FONT" "$MONO_OPTS")"
else
    say "ERROR: FONT_MODE must be 'texlive' or 'fontspec' (got: $FONT_MODE)"; exit 1
fi

FONTBLOCK="% ----- typography and visual style: injected by niori-texi2pdf.sh -----
\\usepackage{fontspec}
\\usepackage{microtype}
\\usepackage[table]{xcolor}"
if [ "$CODE_BOX" = "1" ]; then
    FONTBLOCK="$FONTBLOCK
\\usepackage{framed}% page-breakable boxes for preformatted blocks"
fi
FONTBLOCK="$FONTBLOCK
\\usepackage[
  $PAPER,
  inner=$INNER_MARGIN,
  outer=$OUTER_MARGIN,
  top=$TOP_MARGIN,
  bottom=$BOTTOM_MARGIN,
  headheight=$HEAD_HEIGHT
]{geometry}
\\definecolor{NioriText}{HTML}{$TEXT_COLOR}
\\definecolor{NioriHeading}{HTML}{$HEADING_COLOR}
\\definecolor{NioriAccent}{HTML}{$ACCENT_COLOR}
\\definecolor{NioriCodeBackground}{HTML}{$CODE_BACKGROUND}
\\definecolor{NioriCodeRule}{HTML}{$CODE_RULE}
% NEW: table palette
\\definecolor{NioriTableHeaderFg}{HTML}{$TABLE_HEADER_COLOR}
\\definecolor{NioriTableStripe}{HTML}{$TABLE_STRIPE_COLOR}
\\makeatletter % the box/patch code below uses @-macros: read with the right catcodes
% loud-but-harmless warning if a heading patch stops matching the class
\\newcommand{\\NIORIfail}[1]{\\PackageWarning{niori-texi2pdf}{Heading-font patch failed for #1; heading stays in the main font}}
% NEW: same idea for the table patches
\\newcommand{\\NioriTableFail}[1]{\\PackageWarning{niori-texi2pdf}{Table-style patch failed for #1; using default appearance}}"
if [ "$CODE_BOX" = "1" ]; then
    FONTBLOCK="$FONTBLOCK
% page-breakable background + border for preformatted (code) blocks
\\newenvironment{NioriCodeBox}{%
  \\def\\FrameCommand{\\fboxsep=0.75em\\fboxrule=0.6pt\\fcolorbox{NioriCodeRule}{NioriCodeBackground}}%
  \\framed
  % the backend wraps code in a bare list; if the box opens as the first
  % thing in that item, framed's \\@setminipage re-routes \\everypar and the
  % pending \\@newlist state makes boxed \\par's fail — neutralize it
  \\global\\@newlistfalse}{\\endframed}"
fi
FONTBLOCK="$FONTBLOCK
\\AtBeginDocument{%
  \\color{NioriText}%
  \\hypersetup{%
    colorlinks=true,
    linkcolor=NioriHeading,
    urlcolor=NioriAccent,
    citecolor=NioriHeading,
    bookmarksnumbered=true
  }%
  % --- IBM Plex Mono on chapter/part heads (book-class internals) ---
  \\patchcmd{\\@makechapterhead}{\\raggedright\\normalfont}%
    {\\raggedright\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{chapter head}}%
  \\patchcmd{\\@makeschapterhead}{\\raggedright\\normalfont}%
    {\\raggedright\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{unnumbered chapter head}}%
  % hyperref+nameref rewrite \@part/\@spart into an anchor chain; the
  % original book.cls body ends up in \NR@part/\NR@spart — patch whichever
  % macro currently holds it
  \\ifcsdef{NR@part}{%
    \\patchcmd{\\NR@part}{\\centering\\interlinepenalty\\@M\\normalfont}%
      {\\centering\\interlinepenalty\\@M\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{part head}}%
    \\patchcmd{\\NR@spart}{\\centering\\interlinepenalty\\@M\\normalfont}%
      {\\centering\\interlinepenalty\\@M\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{starred part head}}%
  }{%
    \\patchcmd{\\@part}{\\centering\\interlinepenalty\\@M\\normalfont}%
      {\\centering\\interlinepenalty\\@M\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{part head}}%
    \\patchcmd{\\@spart}{\\centering\\interlinepenalty\\@M\\normalfont}%
      {\\centering\\interlinepenalty\\@M\\normalfont\\NioriHeadingFont}{}{\\NIORIfail{starred part head}}%
  }%"
if [ "$CODE_BOX" = "1" ]; then
    FONTBLOCK="$FONTBLOCK
  % --- background/border for the backend's Texinfopreformatted env ---
  \\let\\NioriPreBegin\\Texinfopreformatted
  \\let\\NioriPreEnd\\endTexinfopreformatted
  \\renewenvironment{Texinfopreformatted}%
    {\\begin{NioriCodeBox}\\NioriPreBegin}%
    {\\NioriPreEnd\\end{NioriCodeBox}}"
fi
FONTBLOCK="$FONTBLOCK
  % --- IBM Plex Mono on all \\@startsection levels
  \\renewcommand\\section{\\@startsection {section}{1}{\\z@}%
    {-3.5ex \\@plus -1ex \\@minus -.2ex}%
    {2.3ex \\@plus.2ex}%
    {\\normalfont\\NioriHeadingFont\\Large\\bfseries}}
  \\renewcommand\\subsection{\\@startsection{subsection}{2}{\\z@}%
    {-3.25ex\\@plus -1ex \\@minus -.2ex}%
    {1.5ex \\@plus .2ex}%
    {\\normalfont\\NioriHeadingFont\\large\\bfseries}}
  \\renewcommand\\subsubsection{\\@startsection{subsubsection}{3}{\\z@}%
    {-3.25ex\\@plus -1ex \\@minus -.2ex}%
    {1.5ex \\@plus .2ex}%
    {\\normalfont\\NioriHeadingFont\\normalsize\\bfseries}}
  \\renewcommand\\paragraph{\\@startsection{paragraph}{4}{\\z@}%
    {3.25ex \\@plus1ex \\@minus.2ex}%
    {-1em}%
    {\\normalfont\\NioriHeadingFont\\normalsize\\bfseries}}
  \\renewcommand\\subparagraph{\\@startsection{subparagraph}{5}{\\parindent}%
    {3.25ex \\@plus1ex \\@minus .2ex}%
    {-1em}%
    {\\normalfont\\NioriHeadingFont\\normalsize\\bfseries}}
  % NEW: --- tables: bold coloured headers, subtle zebra striping ---
  % @multitable header rows (the backend's \\headitem macro).
  \\ifcsdef{headitem}{%
    \\let\\NioriOrigHeaditem\\headitem
    \\renewcommand*\\headitem{\\color{NioriTableHeaderFg}\\bfseries\\NioriOrigHeaditem}%
  }{\\NioriTableFail{headitem (multitable header)}}%
  % @table / @ftable / @vtable term column (the label of a description item).
  \\patchcmd{\\descriptionlabel}{\\normalfont\\bfseries}%
    {\\normalfont\\bfseries\\color{NioriTableHeaderFg}}{}{%
    \\NioriTableFail{descriptionlabel (definition-table term)}}%
  % Zebra-striped body rows in every tabular / longtable.
  \\ifcsdef{AtBeginEnvironment}{%
    \\AtBeginEnvironment{tabular}{\\rowcolors{1}{}{NioriTableStripe}}%
    \\AtBeginEnvironment{longtable}{\\rowcolors{1}{}{NioriTableStripe}}%
  }{\\NioriTableFail{AtBeginEnvironment (zebra striping)}}"
FONTBLOCK="$FONTBLOCK
}
\\makeatother"
if [ -n "$FONT_FEATURES" ]; then
    FONTBLOCK="$FONTBLOCK
\\defaultfontfeatures{$FONT_FEATURES}"
fi
FONTBLOCK="$FONTBLOCK
$MAIN_SPEC
$HEADING_SPEC
$SANS_SPEC
$MONO_SPEC"
if [ -n "$EXTRA_PREAMBLE" ]; then
    FONTBLOCK="$FONTBLOCK
$EXTRA_PREAMBLE"
fi
FONTBLOCK="$FONTBLOCK
% ------------------------------------------------"

if [ "$PRINT_BLOCK" = "1" ]; then
    printf '%s\n' "$FONTBLOCK"
    exit 0
fi

# --- 1. dependency checks ---------------------------------------------------
need texi2any "Install Texinfo >= 7.0 (see the header of this script)."

texinfo_version="$(texi2any --version | grep -oE '[0-9]+\.[0-9]+' | head -1)"
texinfo_major="${texinfo_version%%.*}"
if [ "${texinfo_major:-0}" -lt 7 ]; then
    say "ERROR: texi2any $texinfo_version is too old — 'texi2any --latex' needs Texinfo >= 7.0."
    say "       Upgrade (see TEXINFO_FROM_SOURCE in the header) and retry."
    exit 1
fi
say "[1/4] texi2any $texinfo_version  OK"

if ! command -v "$ENGINE" >/dev/null 2>&1; then
    other="$([ "$ENGINE" = "xelatex" ] && echo lualatex || echo xelatex)"
    if command -v "$other" >/dev/null 2>&1; then
        say "      '$ENGINE' missing, falling back to '$other'."
        ENGINE="$other"
    else
        say "ERROR: neither xelatex nor lualatex found. Install texlive-xetex (or MacTeX)."
        exit 1
    fi
fi

if [ "$FONT_MODE" = "texlive" ]; then
    for f in "$MAIN_UP" "$MAIN_BOLD" "$MAIN_ITALIC" "$MAIN_BOLDITALIC" \
             "$HEADING_UP" "$HEADING_BOLD" "$HEADING_ITALIC" "$HEADING_BOLDITALIC" \
             "$SANS_UP" "$SANS_BOLD" "$SANS_ITALIC" "$SANS_BOLDITALIC" \
             "$MONO_UP" "$MONO_BOLD"; do
        kpsewhich --must-exist "$f" >/dev/null 2>&1 || \
            say "      WARNING: '$f' not found in the TeX tree — install its package (erewhon / plex / inconsolata, see Requirements)."
    done
else
    if command -v fc-list >/dev/null 2>&1; then
        for f in "$MAIN_FONT" "$HEADING_FONT" "$SANS_FONT" "$MONO_FONT"; do
            fc-list | grep -qiF "$f" || say "      WARNING: font '$f' not found by fc-list — compilation may fail or substitute."
        done
    fi
fi

if [ "$CODE_BOX" = "1" ]; then
    kpsewhich framed.sty >/dev/null 2>&1 || \
        say "      WARNING: framed.sty not found — install the 'framed' package (needed by CODE_BOX=1)."
fi

have_latexmk=0
if command -v latexmk >/dev/null 2>&1; then have_latexmk=1; fi

# --- 2. Texinfo -> LaTeX ------------------------------------------------------
say "[2/4] texi2any --latex  ->  $JOB.tex"
texi2any --latex -o "$JOB.tex" "$SRC"

# --- 3. inject fontspec, strip pdflatex-only encodings ------------------------
# (equivalent to setting the CLASS_BEGIN_USEPACKAGE customization variable,
#  but version-tolerant: we post-process whatever preamble was emitted)
# Pass the block via the environment: `awk -v` values undergo escape
# processing (gawk turns \u into "u" and \s into "s", destroying the
# backslashes), while ENVIRON values are taken literally by every awk.
FONTBLOCK="$FONTBLOCK" PAPER="$PAPER" INDEX_COMPACT="$INDEX_COMPACT" awk '
  BEGIN {
      block = ENVIRON["FONTBLOCK"]
      paper = ENVIRON["PAPER"]
      compact = (ENVIRON["INDEX_COMPACT"] == "0") ? 0 : 1
      if (compact) {
          t["cp"] = "Concept Index"; t["fn"] = "Function Index"
          t["vr"] = "Variable Index"; t["ky"] = "Key Index"
          t["tp"] = "Type Index";     t["pg"] = "Program Index"
      }
  }
  !done && /^\\documentclass/ {
      if (paper != "letterpaper" && match($0, /\\documentclass(\[[^]]*\])?\{[A-Za-z]+\}/)) {
          cls = substr($0, RSTART, RLENGTH)
          sub(/.*\{/, "", cls); sub(/\}.*/, "", cls)
          $0 = "\\documentclass[" paper "]{" cls "}"
      }
      print; print block; done = 1; next
  }
  compact && /^\\indexsetup\{/ && $0 !~ /noclearpage/ {
      # Without noclearpage imakeidx issues \cleardoublepage before EVERY
      # \printindex (book class -> jump to next odd page). With several
      # @printindex lists that yields one heading-only page plus a fully
      # blank page between each pair of indices. Switch to the documented
      # "chapter of indices" setup: continuous flow, per-index \section*
      # subheadings.
      line = $0
      sub(/level=\\relax/, "level=\\section*", line)
      if (line ~ /\}%[ \t]*$/) { sub(/\}%[ \t]*$/, ",noclearpage}%", line) }
      else if (line ~ /\}[ \t]*$/) { sub(/\}[ \t]*$/, ",noclearpage}", line) }
      print line; next
  }
  compact && /^\\makeindex\[/ && $0 ~ /,title=\]/ {
      # backend emits "title=" (empty) for every index; give the standard
      # Texinfo indices their usual names so the subheadings say something
      line = $0
      if (match(line, /name=[A-Za-z]+/)) {
          nm = substr(line, RSTART + 5, RLENGTH - 5)
          if (nm in t) sub(/title=\]/, "title=" t[nm] "]", line)
      }
      print line; next
  }
  /\\chaptertitle/ {
      # titleps running heads: put the heading font in front of the marks
      sub(/\[\\chaptername/, "[\\NioriHeadingFont\\chaptername")
      sub(/\{\\chaptername/, "{\\NioriHeadingFont\\chaptername")
      print; next
  }
  /\{\\huge \\bfseries / {
      # title page: backend emits {\huge \bfseries @title} — heading font
      sub(/\{\\huge \\bfseries /, "{\\NioriHeadingFont\\huge \\bfseries ")
      print; next
  }
  # swap the hyperref hidelinks option for colorlinks: hidelinks would
  # kill the palette link colors (it hard-disables coloring, and a
  # later \hypersetup{colorlinks=true} is ignored as "already
  # used"). colorlinks=true at load time gives colored links AND no
  # borders; the \hypersetup in the font block only switches
  # WHICH colors are used. index() avoids ERE bracket-expression traps.
  index($0, "\\usepackage") > 0 && \
      index($0, "[hidelinks]") > 0 && index($0, "{hyperref}") > 0 {
      sub(/hidelinks/, "colorlinks")
      print; next
  }
  /^\\usepackage(\[[^]]*\])?\{inputenc\}/ ||
  /^\\usepackage(\[[^]]*\])?\{fontenc\}/   { print "% stripped for fontspec: " $0; next }
  { print }
' "$JOB.tex" > "$JOB.tex.tmp" && mv "$JOB.tex.tmp" "$JOB.tex"
if ! grep -q 'usepackage{fontspec}' "$JOB.tex"; then
    say "ERROR: font block was not injected — no \\documentclass line found in $JOB.tex?"
    exit 1
fi
idx_msg=""
if [ "$INDEX_COMPACT" = "1" ]; then idx_msg=", indices compacted into one block"; fi
box_msg=""
if [ "$CODE_BOX" = "1" ]; then box_msg=", code boxes on"; fi
tbl_msg=", tables styled"
if [ "$FONT_MODE" = "texlive" ]; then hf="${HEADING_UP%.otf}"; else hf="$HEADING_FONT"; fi
say "[3/4] typography/style injected: fonts=$FONT_MODE, paper=$PAPER, margins=${INNER_MARGIN}/${OUTER_MARGIN}/${TOP_MARGIN}/${BOTTOM_MARGIN}, headings=$hf, heading=$HEADING_COLOR, accent=$ACCENT_COLOR$idx_msg$box_msg$tbl_msg"

# --- 4. compile ---------------------------------------------------------------
if [ "$have_latexmk" -eq 1 ]; then
    say "[4/4] compiling via latexmk + $ENGINE"
    se_flag=""
    if [ "$SHELL_ESCAPE" = "1" ]; then se_flag="-shell-escape"; fi   # lets imakeidx auto-run makeindex
    latexmk "-$ENGINE" -interaction=nonstopmode -halt-on-error $se_flag "$JOB.tex"
else
    # No latexmk: run the engine three times (TOC, @xrefs, index resolution).
    say "[4/4] latexmk not found — running $ENGINE three times"
    "$ENGINE" -interaction=nonstopmode -halt-on-error "$JOB.tex"
    if [ -f "$JOB.idx" ]; then
        command -v makeindex >/dev/null 2>&1 && makeindex "$JOB.idx" >/dev/null 2>&1 || true
    fi
    "$ENGINE" -interaction=nonstopmode -halt-on-error "$JOB.tex"
    "$ENGINE" -interaction=nonstopmode -halt-on-error "$JOB.tex"
fi

[ -f "$JOB.pdf" ] || { say "ERROR: $JOB.pdf was not produced — check the log $JOB.log."; exit 1; }
say "DONE: $(pwd)/$JOB.pdf"
if [ "$KEEP_LATEX" = "1" ]; then
    say "      (generated LaTeX kept in $JOB.tex — edit its preamble for finer font control)"
fi