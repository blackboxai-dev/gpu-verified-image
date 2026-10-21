#!/bin/sh
# The Blackbox login banner: the braille BLACKBOX mark with the machine's
# identity beside it.
#
# A plain file, not generated at launch: this gateway ships the gate as files
# rather than as a base64 boot payload, and a file that can be read on the
# machine is easier to debug than one assembled on the way in.
#
# WIDTHS ARE LITERALS, NEVER COMPUTED. `${#var}` counts BYTES in dash, which is
# /bin/sh on every Debian and Ubuntu image these providers ship, and each
# braille cell is three bytes. A shell-side width calculation therefore comes
# out 3x too large and tears the right border off the frame. The mark below is
# stored already padded to 16 display columns for the same reason.
#
# Frame 68 columns, so it fits an 80-column terminal.

# Overridable only so the test suite can render against a temporary directory.
# pam_motd runs the hook with no environment, so a machine always gets /etc.
: "${BB_DIR:=/etc/blackbox}"
[ -r "$BB_DIR/brand.env" ] && . "$BB_DIR/brand.env"

: "${BLACKBOX_SERVICE:=Blackbox GPU Cloud}"
: "${BLACKBOX_DOCS:=https://docs.blackbox.ai}"
: "${BLACKBOX_SUPPORT:=support@blackbox.ai}"
: "${BLACKBOX_LOGIN:=}"

# The launch does not always know the hardware. The machine always does.
gpu="$BLACKBOX_GPU"
if [ -z "$gpu" ] && command -v nvidia-smi >/dev/null 2>&1; then
  names=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
  if [ -n "$names" ]; then
    gpu="$(echo "$names" | wc -l | tr -d ' ') x $(echo "$names" | head -n 1)"
  fi
fi
[ -z "$gpu" ] && gpu="-"

host="$BLACKBOX_HOST"
[ -z "$host" ] && host=$(hostname 2>/dev/null)
[ -z "$host" ] && host="-"

D=$(printf '\033[38;5;245m')   # frame and labels
W=$(printf '\033[1;97m')       # the wordmark
V=$(printf '\033[97m')         # values
A=$(printf '\033[38;5;202m')   # the mark: nearest 256-colour to brand orange #ff6901
Z=$(printf '\033[0m')

RULE='────────────────────────────────────────────────────────────────────'

blank() { printf '%s│%s%-68s%s│%s\n' "$D" "$Z" '' "$D" "$Z"; }
row()   { printf '%s│%s  %s%-9s%s %s%-56.56s%s%s│%s\n' \
            "$D" "$Z" "$D" "$1" "$Z" "$V" "$2" "$Z" "$D" "$Z"; }

# One line beside the mark: exactly 47 columns and no newline.
title()      { printf '%s%-47.47s%s' "$1" "$2" "$Z"; }
fact()       { printf '%s%-7s%s%s%-40.40s%s' "$D" "$1" "$Z" "$V" "$2" "$Z"; }
side_blank() { printf '%-47s' ''; }
side() {
  case "$1" in
    3) title "$W" 'BLACKBOX.AI' ;;
    4) title "$D" "$BLACKBOX_SERVICE" ;;
    6) if [ "${#host}" -le 40 ]; then fact host "$host"; else side_blank; fi ;;
    7) fact gpu "$gpu" ;;
    8) if [ -n "$BLACKBOX_LOGIN" ]; then fact login "$BLACKBOX_LOGIN"; else side_blank; fi ;;
    *) side_blank ;;
  esac
}

# Already padded to 16 display columns. Do not let the shell pad these.
MARK='      ⢤⣾⣷⣤⣀     
 ⢀⣠⣴⣿⣷⠦⠈⠛⠿⣿⣿⣶⣄⡀ 
⣾⣿⡿⠟⠋      ⠙⠻⢿⣿⣷
⣿⣿⡇          ⢸⣿⣿
⣿⣿⡇          ⢸⣿⣿
⣿⣿⡇          ⠈⢋⣠
⢿⣿⡇⢠⣄      ⣠⣴⣾⣿⡿
 ⠈⠁⠸⣿⣿⣶⣤⣤⣶⣿⣿⠟⠋⠁ 
     ⠉⠛⢿⡿⠛⠉     '

printf '\n'
printf '%s┌%s┐%s\n' "$D" "$RULE" "$Z"
blank
i=0
printf '%s\n' "$MARK" | while IFS= read -r line; do
  i=$((i + 1))
  printf '%s│%s  %s%s%s%3s' "$D" "$Z" "$A" "$line" "$Z" ''
  side "$i"
  printf '%s│%s\n' "$D" "$Z"
done
blank
printf '%s├%s┤%s\n' "$D" "$RULE" "$Z"
if [ "${#host}" -gt 40 ]; then row host "$host"; fi
row billing 'metered per second for as long as this machine runs'
row docs    "$BLACKBOX_DOCS"
row support "$BLACKBOX_SUPPORT"
printf '%s└%s┘%s\n' "$D" "$RULE" "$Z"
printf '\n'
