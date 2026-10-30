#!/usr/bin/env bash
# Temu Farm v2.1 - contenedores virtuales
set -u
R="https://joshda777.github.io/TemuHackBashApp"
D="$HOME/temu-farm"; ST="$HOME/.temu-farm"
PKG=com.einnovation.temu
NAV=com.android.chrome
CLONER="${CLONER:-com.vphonegaga.gp}"
mkdir -p "$D" "$ST"

say(){ printf '\n\033[1;33m%s\033[0m\n' "$*"; }
ok(){ printf '\033[32m  ok\033[0m %s\n' "$*"; }
err(){ printf '\033[31m  !! %s\033[0m\n' "$*"; }
pedir(){ printf '%s ' "$1" >&2; local v; read -r v </dev/tty; printf '%s' "$v"; }
pausa(){ printf '\n\033[36m%s\033[0m\n' "$1"; read -r _ </dev/tty; }
esc(){ printf '%s' "$1" | sed -e 's/ /%s/g' -e 's/[$&<>()|;*?]/\\&/g'; }
uuid(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "00000000-0000-4000-8000-$(date +%N|cut -c1-12)"; }
guardar(){ printf '%s\n%s\n%s\n' "$OBJ" "$HECHAS" "$IDX" > "$ST/state"; }
cargar(){
  if [ -s "$ST/state" ]; then
    OBJ=$(sed -n 1p "$ST/state"); HECHAS=$(sed -n 2p "$ST/state"); IDX=$(sed -n 3p "$ST/state")
  else
    OBJ=0; HECHAS=0; IDX=1
  fi
}

detectar(){
  if [ -n "${PREFIX:-}" ] && [ -d /data/data/com.termux ]; then echo termux
  elif grep -qi '^ID=arch' /etc/os-release 2>/dev/null; then echo arch
  elif [ -n "${MSYSTEM:-}" ] || uname -s | grep -qiE 'mingw|msys'; then echo win
  else echo linux; fi
}

instalar(){
  case "$1" in
    termux) pkg install -y android-tools >/dev/null 2>&1 && ok android-tools || err android-tools ;;
    arch)   sudo pacman -S --needed --noconfirm android-tools >/dev/null 2>&1 && ok adb || err pacman ;;
    linux)
      if command -v apt >/dev/null; then sudo apt install -y adb >/dev/null 2>&1; fi
      if command -v dnf >/dev/null; then sudo dnf install -y android-tools >/dev/null 2>&1; fi
      ;;
    win)
      mkdir -p "$D/pt"
      curl -sL "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -o "$D/p.zip"
      if command -v unzip >/dev/null; then unzip -oq "$D/p.zip" -d "$D/pt"; fi
      export PATH="$D/pt/platform-tools:$PATH"
      grep -q platform-tools "$HOME/.bashrc" 2>/dev/null || \
        echo "export PATH=\"$D/pt/platform-tools:\$PATH\"" >> "$HOME/.bashrc"
      ;;
  esac
}

emparejar(){
  say "Depuracion inalambrica"
  echo "Ajustes > Opciones de desarrollador > Depuracion inalambrica > Emparejar"
  local I C
  I=$(pedir "IP:PUERTO:"); echo
  C=$(pedir "Codigo:"); echo
  adb pair "$I" "$C" || { err "fallo el emparejamiento"; return 1; }
  adb connect localhost:5555 >/dev/null 2>&1 || adb connect 127.0.0.1:5555 >/dev/null 2>&1
  if [ "$(adb get-state 2>/dev/null)" = device ]; then return 0; fi
  err "sin conexion"; return 1
}

_ui(){
  local n
  for n in 1 2 3; do
    adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1
    adb exec-out cat /sdcard/u.xml 2>/dev/null && return 0
    sleep 1
  done
  return 1
}
_loc(){
  _ui | tr '>' '\n' | grep -Ei "$1" \
    | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -1 \
    | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1 \2 \3 \4/' \
    | awk '{print int(($1+$3)/2),int(($2+$4)/2)}'
}
_locU(){
  _ui | tr '>' '\n' | grep -Ei "$1" \
    | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | tail -1 \
    | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1 \2 \3 \4/' \
    | awk '{print int(($1+$3)/2),int(($2+$4)/2)}'
}
tocar(){
  local c
  c=$(_loc "$1")
  [ -z "$c" ] && return 1
  adb shell input tap $c >/dev/null 2>&1
  return 0
}
mantener(){
  local c
  c=$(_locU "$1")
  [ -z "$c" ] && return 1
  adb shell input swipe $c $c 900 >/dev/null 2>&1
  return 0
}
esperar(){
  local i=0
  while [ "$i" -lt "${2:-25}" ]; do
    if tocar "$1"; then sleep 1; return 0; fi
    sleep 1; i=$((i+1))
  done
  return 1
}
escribir(){ adb shell input text "$(esc "$1")" >/dev/null 2>&1; }
desbloq(){
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  adb shell wm dismiss-keyguard >/dev/null 2>&1
  sleep 1
}
dialogos(){
  local i
  for i in $(seq 1 8); do
    tocar "Aceptar|Accept|Entendido|Got it|Permitir|Allow|Ahora no|Not now|Omitir|Skip|Más tarde|Later|Instalar de todos modos|Install anyway|Continuar|Continue" && continue
    sleep 1
  done
}

abrir_cloner(){
  adb shell monkey -p "$CLONER" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  sleep 2
  dialogos
}
nombrar(){ printf 'B%02d' "$1"; }

clonar(){
  local N="$1" E="$2" c k
  abrir_cloner
  tocar "Añadir|Add|Agregar|Crear app|Crear" || mantener "más|more|Más"
  sleep 2
  tocar "$E" || tocar "$N"
  sleep 2
  tocar "Crear|Create|Clonar|Clone|Añadir|Add|Aceptar|OK|Clonar app"
  sleep 6
  c=$(_locU "$E")
  if [ -n "$c" ]; then
    adb shell input swipe $c $c 900 >/dev/null 2>&1
    sleep 2
    if tocar "Renombrar|Rename|Editar|Edit|Nombre|Name"; then
      adb shell input keyevent KEYCODE_MOVE_END >/dev/null 2>&1
      for k in 1 2 3 4 5 6 7 8; do adb shell input keyevent KEYCODE_DEL >/dev/null 2>&1; done
      escribir "$2"
      tocar "Aceptar|OK|Guardar|Save|Listo|Done"
      sleep 2
    fi
  fi
}

abrir_botella(){
  abrir_cloner
  if tocar "$1"; then
    sleep 3
    tocar "Abrir|Open|Ejecutar|Iniciar"
    sleep 6
  fi
}

id_de(){ adb shell pm list users 2>/dev/null | grep -o "UserInfo{[0-9]*:$1:" | grep -o '[0-9]*' | head -1; }

blindar(){
  local U=$1 p o
  adb shell settings --user "$U" put secure advertising_id "$(uuid)" >/dev/null 2>&1
  adb shell settings --user "$U" put secure limit_ad_tracking 0 >/dev/null 2>&1
  adb shell pm clear --user "$U" "$PKG" >/dev/null 2>&1
  for p in ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION READ_PHONE_STATE READ_CONTACTS READ_CALL_LOG BLUETOOTH_SCAN POST_NOTIFICATIONS; do
    adb shell pm revoke --user "$U" "$PKG" "android.permission.$p" >/dev/null 2>&1
    adb shell pm set-permission-flags --user "$U" "$PKG" "android.permission.$p" user-fixed >/dev/null 2>&1
  done
  for o in FINE_LOCATION COARSE_LOCATION READ_PHONE_STATE READ_CONTACTS; do
    adb shell appops set --user "$U" "$PKG" "$o" ignore >/dev/null 2>&1
  done
}

cuenta(){
  adb shell am start -a android.settings.ADD_ACCOUNT_SETTINGS --esa account_types com.google >/dev/null 2>&1
  esperar "Email|Correo|teléfono|phone" 40 || return 1
  tocar "Email|Correo|teléfono|phone"
  escribir "$1"
  esperar "Next|Siguiente" 12 || adb shell input keyevent KEYCODE_ENTER >/dev/null 2>&1
  sleep 4
  esperar "password|contraseña|Password" 25 || return 1
  tocar "password|contraseña|Password"
  escribir "$2"
  esperar "Next|Siguiente" 12 || adb shell input keyevent KEYCODE_ENTER >/dev/null 2>&1
  sleep 5
  local i=0
  while [ "$i" -lt 120 ]; do
    tocar "Aceptar|Accept|Acepto|I agree|Continuar|Continue|Permitir|Allow|Listo|Done|Siguiente|Next" && continue
    if _loc "Cuenta|Account|Gmail" >/dev/null; then break; fi
    sleep 2; i=$((i+2))
  done
}

una(){
  local n=$1 E L EM PW ID
  E=$(nombrar "$n")
  say "Botella $((HECHAS+1)) de $OBJ"
  if [ "$MOTOR" = clones ]; then
    clonar "$NAV" "$E-nav"
    clonar "$PKG" "$E"
    abrir_botella "$E"
    if [ -s "$D/cuentas.txt" ] && [ "$(wc -l < "$D/cuentas.txt")" -ge "$IDX" ]; then
      L=$(sed -n "${IDX}p" "$D/cuentas.txt")
      EM=${L%%|*}; PW=${L#*|}
      IDX=$((IDX+1)); guardar
      cuenta "$EM" "$PW"
    else
      pausa "Inicia sesion con Google en esta botella y pulsa Enter."
    fi
    abrir_cloner
    tocar "$E-nav"
    sleep 3
    tocar "Abrir|Open"
    sleep 5
    if esperar "Buscar|Search|URL|Dirección" 20; then
      tocar "Buscar|Search|URL|Dirección"
      escribir "$LINK"
      adb shell input keyevent KEYCODE_ENTER >/dev/null 2>&1
      sleep 6
    fi
    pausa "Confirma que el enlace abrio dentro del contenedor y pulsa Enter."
  else
    adb shell pm create-user "T$n" >/dev/null 2>&1
    ID=$(id_de "T$n")
    if [ -z "$ID" ]; then err "tope de usuarios"; return 1; fi
    adb shell am start-user "$ID" >/dev/null 2>&1
    adb shell pm install-existing --user "$ID" "$PKG" >/dev/null 2>&1
    blindar "$ID"
    adb shell am switch-user "$ID"
    sleep 2; desbloq
    adb shell am start --user "$ID" -a android.intent.action.VIEW -d "$LINK" >/dev/null 2>&1
    pausa "Registra en esta botella y pulsa Enter."
    adb shell am switch-user 0 >/dev/null 2>&1
  fi
  HECHAS=$((HECHAS+1)); guardar
  ok "botella $n cerrada"
}

lote(){
  local n=$1 i
  for i in $(seq 1 "$n"); do una "$i" || break; done
}

cmd_estado(){
  cargar
  echo "Motor: $MOTOR"; echo "Objetivo: $OBJ"
  echo "Hechas: $HECHAS"; echo "Restantes: $((OBJ-HECHAS))"
}

cmd_borrar(){
  local i E ID
  [ "${1:-}" = todas ] || return 0
  if [ "$MOTOR" = clones ]; then
    abrir_cloner
    for i in $(seq 1 50); do
      E=$(nombrar "$i")
      mantener "$E" && tocar "Eliminar|Delete|Borrar|Quitar" && tocar "Aceptar|OK|Eliminar|Delete"
    done
  else
    for i in $(seq 1 12); do
      ID=$(id_de "T$i")
      if [ -n "$ID" ]; then adb shell pm remove-user "$ID" >/dev/null 2>&1; fi
    done
  fi
  rm -f "$ST/state"
  ok "limpio"
}

cmd_nuevo(){
  LINK=$(pedir "Enlace de invitacion:"); echo
  OBJ=$(pedir "Cuantas botellas (max 50):"); echo
  if [ "$OBJ" -gt 50 ]; then OBJ=50; fi
  HECHAS=0; IDX=1
  guardar
  printf '%s' "$LINK" > "$ST/link"
  say "Corre: bash $D/farm.sh reanudar"
}

cmd_run(){
  cargar
  if [ "$OBJ" -eq 0 ]; then err "sin configurar"; return 1; fi
  while [ "$HECHAS" -lt "$OBJ" ]; do
    say "Botella $((HECHAS+1))"
    lote 1
    guardar
  done
  say "Completado $HECHAS/$OBJ"
}

main(){
  local M="${1:-}" M2 OS
  LINK=$(cat "$ST/link" 2>/dev/null || true)
  MOTOR=$(cat "$ST/motor" 2>/dev/null || echo clones)
  case "$M" in
    estado)   cargar; cmd_estado; exit 0 ;;
    borrar)   cmd_borrar "${2:-}"; exit 0 ;;
    reanudar) cmd_run; exit 0 ;;
    nuevo)    cmd_nuevo; exit 0 ;;
  esac

  say "TEMU FARM v2.1"
  OS=$(detectar)
  instalar "$OS"
  if [ "$(adb get-state 2>/dev/null)" != device ]; then emparejar || exit 1; fi
  adb shell svc power stayon true >/dev/null 2>&1
  adb shell settings put system screen_off_timeout 1800000 >/dev/null 2>&1

  if [ "$M" = "--usuarios" ]; then
    printf 'usuarios' > "$ST/motor"
  elif [ "$M" = "--clones" ]; then
    printf 'clones' > "$ST/motor"
  else
    echo "Motor: 1) clones (hasta 50)  2) usuarios (4-8)"
    M2=$(pedir "Elige [1]:")
    if [ "$M2" = 2 ]; then printf 'usuarios' > "$ST/motor"; else printf 'clones' > "$ST/motor"; fi
  fi
  MOTOR=$(cat "$ST/motor")

  if ! adb shell pm list packages 2>/dev/null | grep -q "$PKG"; then
    err "instala Temu una vez y vuelve a correr"; exit 1
  fi
  if [ "$MOTOR" = clones ] && ! adb shell pm list packages 2>/dev/null | grep -q "$CLONER"; then
    err "falta el clonador. Instala VPhoneGaGa desde Play Store y repite."; exit 1
  fi

  [ -f "$D/farm.sh" ] || curl -sL "$R/i.sh" -o "$D/farm.sh"
  chmod +x "$D/farm.sh"
  cmd_nuevo
  cmd_run
}

main "$@"
