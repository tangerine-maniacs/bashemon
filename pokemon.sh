#!/usr/bin/env bash

POKEDEX_FILE="pokedex.cfg"
TIPOS_FILE="tipos.cfg"
CONFIG_FILE="config.cfg"

LOG_FILE="log.cfg"

function usage() {
  echo "Bashémon: Proyecto SSOOI"
  echo "Uso: $0 [-g]"
  echo " -g: Mostrar los nombres de los integrantes del equipo"
  exit 1
}

# Esta función asume que el fichero config.cfg incluye esas claves, sólo esas claves
# y sólo una de cada.
function read_config() {
  LOG_FILE=$(grep '^LOG=' $CONFIG_FILE | sed -e 's/LOG=//')
  if [ -z $LOG_FILE ]; then
    return 1
  fi

  VICTORIAS=$(grep '^VICTORIAS=' $CONFIG_FILE | sed -e 's/VICTORIAS=//')
  if [ -z $VICTORIAS ]; then
    VICTORIAS=0 # victorias va a ser 0 por defecto (si no existe)
  fi

  NOMBRE_JUGADOR=$(grep '^NOMBRE=' $CONFIG_FILE | sed -e 's/VICTORIAS=//')
  POKEMON_JUGADOR=$(grep '^POKEMON=' $CONFIG_FILE | sed -e 's/VICTORIAS=//')
}

function writeCfg() {
  :
}

function menuPrincipal {
  while true; do
    echo "C) CONFIGURACION"
    echo "J) JUGAR"
    echo "E) ESTADÍSTICAS"
    echo "R) REINICIO"
    echo "S) SALIR"
    read -p ' "POKEMON EDICION USAL". Introduzca una opción >>' opcion
    case ${opcion^^} in
      "C")
        mConfig;;
      "J")
        mJugar;;
      "E")
        mEstadisticas;;
      "R")
        mReinicio;;
      "S")
        mSalir;;
      *) 
        echo "Opción incorrecta";;
    esac
  done
}

function mConfig {
  local esOpcionValida=false
  while ! $esOpcionValida; do
    echo "N) CAMBIAR NOMBRE DEL JUGADOR"
    echo "P) CAMBIAR POKÉMON ELEGIDO"
    echo "V) CAMBIAR Nº VICTORIAS"
    echo "L) CAMBIAR UBICACIÓN DE ARCHIVO DE LOG"
    echo "A) ATRÁS"
    read -p ' ¿Qué desea hacer? >>' opcion
    case ${opcion^^} in
      "N")
        local esOpcionValida=true
        echo "WIP";;
      "P")
        local esOpcionValida=true
        echo "WIP";;
      "V")
        local esOpcionValida=true
        echo "WIP";;
      "L")
        local esOpcionValida=true
        echo "WIP";;
      "A")
        local esOpcionValida=true
        return;;
      *) 
        echo "Opción incorrecta";;
    esac
  done
}

function mJugar() {
  # Read pokemons in a (Pokemon, type) form 
  declare -a pokenames 
  declare -a poketypes

  for i in {0..151..1}
  do
    padded_i=$(printf "%03d" $(($i + 1)))
    pokenames[$i]=$(grep "$padded_i" pokedex.cfg | cut -d '=' -f 2)
    poketypes[$i]=$(grep "$padded_i" tipos.cfg | cut -d '=' -f 2)

  done


  # Choose pokemons 
  player_pokemon=$(randRange 0 151)
  enemy_pokemon=$(randRange 0 151)


  printf "${pokenames[$player_pokemon]} vs. ${pokenames[$enemy_pokemon]}\n\n"


  # BIG FAT TABLE
  declare -A types=(
    ["normal"]="-ro fa"
    ["lucha"]="no ro hi-vo ve bi fa ps"
    ["volador"]="lu bi pl-ro el"
    ["veneno"]="bi pl-ti ro fa"
    ["tierra"]="ve ro el-vo bi pl"
    ["roca"]="vo bi hi-lu ti"
    ["bicho"]="ve ro fa pl ps-lu vo"
    ["fantasma"]="-no ps"
    ["fuego"]="ro bi pl hi-ag dr"
    ["agua"]="ti fu-pl dr"
    ["planta"]="ti ag-vo ve ro bi fu dr"
    ["electrico"]="vo ag-ti pl dr"
    ["psiquico"]="lu ve-"
    ["hielo"]="vo ti pl dr-ag"
    ["dragon"]="-"
  )


  # Sleep for intensity
  printf "${pokenames[$player_pokemon]} le pega tremendos putazos a ${pokenames[$enemy_pokemon]}"
  sleeps=$(randRange 2 6)
  for i in $(seq 0 $sleeps)
  do
    printf '.'
    
    sleep 1
  done

  # Check who wins
  player_type=${poketypes[$player_pokemon]}
  enemy_type=$(echo ${poketypes[$enemy_pokemon]} | cut -b -2)

  typeline=${types[$player_type]}

  if echo $typeline | cut -d '-' -f 1 | grep -q "$enemy_type"; then
    # Player wins
    echo "${pokenames[$player_pokemon]} detruye a "${pokenames[$enemy_pokemon]} 

  elif echo $typeline | cut -d '-' -f 2 | grep -q "$enemy_type"; then
    # Enemy wins
    echo "${pokenames[$enemy_pokemon]} esquiva y te cambia el horoscopo de severa contusion craneal"

  else
    # Draw
    echo "Empate!"

  fi
}

function mEstadisticas() {
  :
}

function mReinicio() {
  # Vaciar el archivo log
  printf "" > $LOG_FILE 

  # Cambiar las configuraciones
  echo "NOMBRE=" > config.cfg
  echo "POKEMON=" >> config.cfg
  echo "VICTORIAS=" >> config.cfg
  echo "LOG=$LOG_FILE" >> config.cfg
}

function mSalir() {
  exit 0
}

# log $jugador $pokemonJugador $pokemonRival $ganadorPartida - guardar datos en el fichero log
function log() {
  fecha=$(date +%d%m%Y)
  hora=$(date +%H)
  echo "$fecha | $hora | $1 | $2 | $3 | $4 | $5" >> $LOG_FILE
}

function readLog() {
  :
}

# randRange $1 $2 genera un número aleatorio en [$1, $2)
function randRange() {
  local min=$1
  local max=$2
  echo $((min + $RANDOM % (max - min)))
}

function loadCoolPokegraphics() {
  :
}
function coolGraphics() {
  :
}

if [ $# -eq 0 ]; then
  # programa
  read_config
  menuPrincipal
elif [[ $# -eq 1 && "$1" == "-g" ]]; then
  # nuestros nombres
  echo "Grupo compuesto por:"
  echo "***NAME REDACTED*** (***ID REDACTED***) <***EMAIL REDACTED***>"
  echo "***NAME REDACTED***  (***ID REDACTED***) <***EMAIL REDACTED***>"
  exit 0
else
  echo "ERROR: Argumentos introducidos inválidos."
  usage
fi
