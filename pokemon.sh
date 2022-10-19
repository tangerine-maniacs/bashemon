#!/usr/bin/env bash

# === CONSTANTES ===
POKEDEX_FILE="pokedex.cfg"
TIPOS_FILE="tipos.cfg"
CONFIG_FILE="config.cfg"

declare -A TABLA_TIPOS=(
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

# === config.cfg === 
# Valores cargados de config.cfg
LOG_FILE=""
NOMBRE_JUGADOR=""
VICTORIAS=""
POKEMON_JUGADOR=""

function usage {
  echo "Bashémon: Proyecto SSOOI"
  echo "Uso: $0 [-g]"
  echo " -g: Mostrar los nombres de los integrantes del equipo"
  exit 1
}

# Esta función asume que el fichero config.cfg incluye esas claves, sólo esas claves
# y sólo una de cada.
function readConfig {
  LOG_FILE=$(grep '^LOG=' $CONFIG_FILE | sed -e 's/LOG=//')
  if [ -z $LOG_FILE ]; then
    return 1
  fi

  VICTORIAS=$(grep '^VICTORIAS=' $CONFIG_FILE | sed -e 's/VICTORIAS=//')
  if [ -z $VICTORIAS ]; then
    VICTORIAS=0 # victorias va a ser 0 por defecto (si no existe)
  fi

  NOMBRE_JUGADOR=$(grep '^NOMBRE=' $CONFIG_FILE | sed -e 's/NOMBRE=//')
  POKEMON_JUGADOR=$(grep '^POKEMON=' $CONFIG_FILE | sed -e 's/POKEMON=//')
}

function writeConfig {
  printf "NOMBRE=${NOMBRE_JUGADOR}\nPOKEMON=${POKEMON_JUGADOR}\nVICTORIAS=${VICTORIAS}\nLOG=${LOG_FILE}" > $CONFIG_FILE
}

# Read pokemons in a (Pokemon, type) form 
declare -a pokenames 
declare -a poketypes
function readPokes {
  # TODO: Make pokenames and poketypes uppercase
  for i in {0..151..1}
  do
    padded_i=$(printf "%03d" $(($i + 1)))
    pokenames[$i]=$(grep "$padded_i" pokedex.cfg | cut -d '=' -f 2)
    poketypes[$i]=$(grep "$padded_i" tipos.cfg | cut -d '=' -f 2)
  done
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
    echo "N) CAMBIAR NOMBRE DEL JUGADOR          (Actual: ${NOMBRE_JUGADOR})"
    echo "P) CAMBIAR POKÉMON ELEGIDO             (Actual: ${POKEMON_JUGADOR})"
    echo "V) CAMBIAR Nº VICTORIAS                (Actual: ${VICTORIAS})"
    echo "L) CAMBIAR UBICACIÓN DE FICHERO DE LOG (Actual: ${LOG_FILE})"
    echo "A) ATRÁS"
    read -p ' ¿Qué desea hacer? >>' opcion
    case ${opcion^^} in
      "N")
        local esOpcionValida=true
        read -p "Introduce tu nombre de jugador: " NOMBRE_JUGADOR
        writeConfig;;
      "P")
        local esOpcionValida=true
        # TODO: No dejar elegir un pokémon que no existe.
        read -p "Introduce tu pokemon elegido: " POKEMON_JUGADOR
        writeConfig;;
      "V")
        local esOpcionValida=true
        # TODO: Asegurarse de que victorias es un número.
        read -p "Introduce el número de victorias hasta el momento: " VICTORIAS
        writeConfig;;
      "L")
        local esOpcionValida=true
        # TODO: Dar error si la nueva ubicación es incorrecta
        read -p "Introduce la nueva ubicación del fichero de log: " LOG_FILE
        writeConfig;;
      "A")
        local esOpcionValida=true
        return;;
      *) 
        echo "Opción incorrecta";;
    esac
  done
}

function mJugar {
  # Choose pokemons 
  player_pokemon=$(randRange 0 151)
  enemy_pokemon=$(randRange 0 151)

  printf "${pokenames[$player_pokemon]} vs. ${pokenames[$enemy_pokemon]}\n\n"

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

  typeline=${TABLA_TIPOS[$player_type]}

  if echo $typeline | cut -d '-' -f 1 | grep -q "$enemy_type"; then
    # Player wins
    echo "${pokenames[$player_pokemon]} detruye a ${pokenames[$enemy_pokemon]}" 
    log $NOMBRE_JUGADOR ${pokenames[$player_pokemon]} ${pokenames[$enemy_pokemon]} "Jugador"
  elif echo $typeline | cut -d '-' -f 2 | grep -q "$enemy_type"; then
    # Enemy wins
    echo "${pokenames[$enemy_pokemon]} esquiva y te cambia el horoscopo de severa contusion craneal"
    log $NOMBRE_JUGADOR ${pokenames[$player_pokemon]} ${pokenames[$enemy_pokemon]} "Rival"
  else
    # Draw
    echo "Empate!"
    # TODO: Preguntar si ponemos empate en caso de que empate
    log $NOMBRE_JUGADOR ${pokenames[$player_pokemon]} ${pokenames[$enemy_pokemon]} "Empate"
  fi
}

# TODO: Si hay varios con el máximo, cuál cogemos?
function maxDicc {
  local -n dicc=$1

  max_key=!dicc[0]
  max_val=dicc[0]

  for key in "${!dicc[@]}"; do
    if [[ ${dicc[$key]} -gt $max_val ]]; then
      max_val=${dicc[$key]}
      max_key=$key
    fi
  done

  echo $max_key 
}

function mEstadisticas {
  local ncombates=0
  local nganados=0
 
  declare -A poke_ganados_jugador
  declare -A poke_ganados_rival

  while read -r line; do
    ncombates=$((ncombates+1))

    # Si pone jugador en la línea, ese combate lo ha ganado el jugador.
    # FIX: Que el jugador se llame 'Jugador' o que tenga '|' en su nombre
    if grep -q 'Jugador' <<< $line; then
      nganados=$((nganados+1))
      # Nombre del pokemon ganador
      local poke_nombre=$(echo $line | cut -d'|' -f4 | xargs)
      poke_ganados_jugador[$poke_nombre]=$((${poke_ganados_jugador[$poke_nombre]}+1))
    elif grep -q 'Rival' <<< $line; then
      # Nombre del pokemon ganador
      local poke_nombre=$(echo $line | cut -d'|' -f5 | xargs)

      poke_ganados_rival[$poke_nombre]=$((${poke_ganados_rival[$poke_nombre]}+1))
    fi
  done < info.log


  # Convertir diccionario a lista n-victorias, nombres de pokemon
  echo "Número total de combates: $ncombates"
  echo "Número de combates ganados por el jugador: $nganados"

  max_pgj=$(maxDicc poke_ganados_jugador)
  max_pgr=$(maxDicc poke_ganados_rival)
  echo "Pokémon del jugador con más victorias (${poke_ganados_jugador[$max_pgj]}): $max_pgj"
  echo "Pokémon del rival con más victorias (${poke_ganados_rival[$max_pgr]}): $max_pgr"
}

function mReinicio {
  # Vaciar el archivo log
  printf "" > $LOG_FILE 

  # Cambiar las configuraciones
  NOMBRE_JUGADOR=""
  POKEMON=""
  VICTORIAS=""
  # LOG_FILE="" mantenemos log_file
  writeConfig
}

function mSalir {
  exit 0
}

# log $jugador $pokemonJugador $pokemonRival $ganadorPartida - guardar datos en el fichero log
function log {
  fecha=$(date +%d%m%Y)
  hora=$(date +%H) # TODO: Hora? Hora y minutos? 
  echo "$fecha | $hora | $1 | $2 | $3 | $4 | $5" >> $LOG_FILE
}

# randRange $1 $2 genera un número aleatorio en [$1, $2)
function randRange {
  local min=$1
  local max=$2
  echo $((min + $RANDOM % (max - min)))
}

function loadCoolPokegraphics {
  :
}
function coolGraphics {
  :
}

if [ $# -eq 0 ]; then
  # programa
  echo "Cargando pokémon..."
  readPokes
  readConfig
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
