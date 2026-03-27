;;; doom-solarized-semantic-theme.el --- semantic dimming on solarized dark -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Author: arenadev
;; Based on: doom-solarized-dark-high-contrast by jmorag
;; Source: https://ethanschoonover.com/solarized
;;
;;; Commentary:
;;
;; Structural noise (keywords, punctuation, brackets, operators) is dimmed.
;; Semantic signal (definitions, constants, readonly) is highlighted.
;; Regular usage (function calls, variables, builtins) inherits default text.
;;
;;; Code:

(require 'doom-themes)

;;;
;;; Variables

(defgroup doom-solarized-semantic-theme nil
  "Options for the `doom-solarized-semantic' theme."
  :group 'doom-themes)

(defcustom doom-solarized-semantic-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-solarized-semantic-theme
  :type 'boolean)

(defcustom doom-solarized-semantic-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-solarized-semantic-theme
  :type 'boolean)

(defcustom doom-solarized-semantic-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-solarized-semantic-theme
  :type '(choice integer boolean))


;;;
;;; Theme definition

(def-doom-theme doom-solarized-semantic
  "Solarized dark with semantic dimming."
  :family 'doom-solarized
  :background-mode 'dark

  ;; name        default   256       16
  ((bg         '("#002732" "#002732" "black"      ))
   (fg         '("#8d9fa1" "#8d9fa1" "brightwhite"))

   (bg-alt     '("#00212B" "#00212B" "black"       ))
   (fg-alt     '("#60767e" "#60767e" "white"       ))

   (base0      '("#01323d" "#01323d" "black"       ))
   (base1      '("#03282F" "#03282F" "brightblack" ))
   (base2      '("#00212C" "#00212C" "brightblack" ))
   (base3      '("#13383C" "#13383C" "brightblack" ))
   (base4      '("#56697A" "#56697A" "brightblack" ))
   (base5      '("#62787f" "#62787f" "brightblack" ))
   (base6      '("#96A7A9" "#96A7A9" "brightblack" ))
   (base7      '("#788484" "#788484" "brightblack" ))
   (base8      '("#626C6C" "#626C6C" "white"       ))

   (grey       base4)
   (red        '("#ec423a" "#ec423a" "red"          ))
   (orange     '("#db5823" "#db5823" "brightred"    ))
   (green      '("#93a61a" "#93a61a" "green"        ))
   (teal       '("#35a69c" "#33aa99" "brightgreen"  ))
   (yellow     '("#c49619" "#c49619" "yellow"       ))
   (blue       '("#3c98e0" "#3c98e0" "brightblue"   ))
   (dark-blue  '("#3F88AD" "#2257A0" "blue"         ))
   (magenta    '("#e2468f" "#e2468f" "magenta"      ))
   (violet     '("#7a7ed2" "#7a7ed2" "brightmagenta"))
   (cyan       '("#3cafa5" "#3cafa5" "brightcyan"   ))
   (dark-cyan  '("#03373f" "#03373f" "cyan"         ))

   ;; Structural noise — fades into the background
   (noise      '("#2f4f4f" "#2f4f4f" "brightblack"  ))

   ;; --- Semantic class overrides (the core of the design) ---
   ;; Structural noise dims down:
   (highlight      blue)
   (vertical-bar   (doom-darken base1 0.5))
   (selection       dark-blue)
   (builtin        fg)           ; plain text (was blue)
   (comments       base5)
   (doc-comments   teal)
   (constants      violet)       ; distinct violet (was blue)
   (functions      fg)           ; plain text (was blue)
   (keywords       noise)        ; dimmed (was green)
   (methods        fg)           ; plain text (was cyan)
   (operators      fg)           ; plain text (was orange)
   (type           yellow)
   (strings        green)
   (variables      fg)
   (numbers        violet)
   (region         base0)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    blue)
   (vc-added       "#119e44")
   (vc-deleted     red)

   ;; Modeline
   (-modeline-bright doom-solarized-semantic-brighter-modeline)
   (-modeline-pad
    (when doom-solarized-semantic-padded-modeline
      (if (integerp doom-solarized-semantic-padded-modeline)
          doom-solarized-semantic-padded-modeline 4)))

   (modeline-fg     'unspecified)
   (modeline-fg-alt base5)

   (modeline-bg
    (if -modeline-bright
        base3
      `(,(doom-darken (car bg) 0.15) ,@(cdr base0))))
   (modeline-bg-alt
    (if -modeline-bright
        base3
      `(,(doom-darken (car bg) 0.1) ,@(cdr base0))))
   (modeline-bg-inactive     (doom-darken bg 0.1))
   (modeline-bg-inactive-alt `(,(car bg) ,@(cdr base1))))


  ;;;; Face overrides
  (
   ;; --- Structural noise: dimmed ---
   ((font-lock-keyword-face &override) :foreground noise :weight 'normal)
   ((font-lock-bracket-face &override) :foreground noise)
   ((font-lock-delimiter-face &override) :foreground noise)
   ((font-lock-punctuation-face &override) :foreground noise)
   ((font-lock-operator-face &override) :foreground fg)

   ;; --- Types: keep yellow, drop italic ---
   ((font-lock-type-face &override) :slant 'normal)

   ;; --- Builtins: plain text, drop italic ---
   ((font-lock-builtin-face &override) :foreground fg :slant 'normal)

   ;; --- Constants: violet, normal weight ---
   ((font-lock-constant-face &override) :foreground violet :weight 'normal)

   ;; --- Functions: plain text ---
   ((font-lock-function-name-face &override) :foreground fg)
   ((font-lock-function-call-face &override) :foreground fg)

   ;; --- Comments ---
   ((font-lock-comment-face &override)
    :slant 'italic
    :background (if doom-solarized-semantic-brighter-comments
                    (doom-lighten bg 0.05)
                  'unspecified))

   ;; --- Eglot semantic tokens ---
   ;; Definitions: "new name introduced here" — bold+italic, inherits text color
   (eglot-semantic-definition-face :foreground fg :weight 'semi-bold :slant 'italic)
   (eglot-semantic-declaration-face :foreground fg :weight 'semi-bold :slant 'italic)
   ;; Specific definition token type — highlighted blue
   (eglot-semantic-definition :foreground blue)
   ;; Readonly/const: same violet as constants
   (eglot-semantic-readonly-face :foreground violet :weight 'normal)
   ;; Methods/functions: plain text
   (eglot-semantic-method-face :foreground fg)
   (eglot-semantic-method :foreground fg)
   (eglot-semantic-function-face :foreground fg)

   ;; --- Base UI ---
   ((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg)
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground (if -modeline-bright base8 highlight))
   (tooltip :background bg-alt :foreground fg)

   ;;;; centaur-tabs
   (centaur-tabs-active-bar-face :background blue)
   (centaur-tabs-modified-marker-selected :inherit 'centaur-tabs-selected :foreground blue)
   (centaur-tabs-modified-marker-unselected :inherit 'centaur-tabs-unselected :foreground blue)
   ;;;; company / corfu
   (company-tooltip-selection :background dark-cyan)
   ;;;; css-mode
   (css-proprietary-property :foreground orange)
   (css-property :foreground green)
   (css-selector :foreground blue)
   ;;;; doom-modeline
   (doom-modeline-bar :background blue)
   (doom-modeline-evil-emacs-state :foreground magenta)
   (doom-modeline-evil-insert-state :foreground blue)
   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground violet)
   (markdown-url-face :foreground teal :weight 'normal)
   (markdown-reference-face :foreground base6)
   ((markdown-bold-face &override) :foreground fg)
   ((markdown-italic-face &override) :foreground fg-alt)
   ;;;; outline (org-mode)
   ((outline-1 &override) :foreground blue)
   ((outline-2 &override) :foreground green)
   ((outline-3 &override) :foreground teal)
   ((outline-4 &override) :foreground (doom-darken blue 0.2))
   ((outline-5 &override) :foreground (doom-darken green 0.2))
   ((outline-6 &override) :foreground (doom-darken teal 0.2))
   ((outline-7 &override) :foreground (doom-darken blue 0.4))
   ((outline-8 &override) :foreground (doom-darken green 0.4))
   ;;;; org
   ((org-block &override) :background base0)
   ((org-block-begin-line &override) :foreground comments :background base0)
   ;;;; git-gutter-fringe
   (git-gutter-fr:modified :foreground vc-modified)
   ;;;; vterm
   (vterm-color-black   :background (doom-lighten base0 0.75) :foreground base0)
   (vterm-color-red     :background (doom-lighten red 0.75) :foreground red)
   (vterm-color-green   :background (doom-lighten green 0.75) :foreground green)
   (vterm-color-yellow  :background (doom-lighten yellow 0.75) :foreground yellow)
   (vterm-color-blue    :background (doom-lighten blue 0.75) :foreground blue)
   (vterm-color-magenta :background (doom-lighten magenta 0.75) :foreground magenta)
   (vterm-color-cyan    :background (doom-lighten cyan 0.75) :foreground cyan)
   (vterm-color-white   :background (doom-lighten base8 0.75) :foreground base8)
   ;;;; solaire-mode
   (solaire-mode-line-face
    :inherit 'mode-line
    :background modeline-bg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :background modeline-bg-inactive-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-alt)))
   ))

;;; doom-solarized-semantic-theme.el ends here
