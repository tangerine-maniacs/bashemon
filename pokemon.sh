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

# === funciones ===
# Función: usage
# Imprime cómo usar el script (argumentos), y devuelve 0 (ejecución 
# satisfactoria).
function usage {
  echo "Bashémon: Proyecto SSOOI"
  echo "Uso: $0 [-g]"
  echo " -g: Mostrar los nombres de los integrantes del equipo"
  exit 0
}

# Esta función asume que el fichero config.cfg incluye esas claves, sólo esas 
# claves y sólo una de cada.
function cargarConfig {
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

# Función: guardarConfig
# Genera un archivo de configuración y lo guarda, basándose en los valores de 
# las variables globales (declaradas en la sección 'config.cfg')
function guardarConfig {
  printf "NOMBRE=${NOMBRE_JUGADOR}\nPOKEMON=${POKEMON_JUGADOR}\nVICTORIAS=${VICTORIAS}\nLOG=${LOG_FILE}" > $CONFIG_FILE
}

# Función: leerPokes
# Lee los pokemon y los tipos de sus respectivos archivos, y los almacena en dos
# listas globales, 'NOMBRES_POKEMON' y 'TIPOS_POKEMON'. 
declare -a NOMBRES_POKEMON 
declare -a TIPOS_POKEMON
function leerPokes {
  # Para leer los pokemon en orden (en caso de que el archivo tenga alguna 
  # línea desordenada) generamos los números de las líneas (rellenando con 0s a
  # la izquierda) y leemos las líneas que tienen esos números.
  for i in {0..151..1}; do
    i_relleno=$(printf "%03d" $(($i + 1)))
    NOMBRES_POKEMON[$i]=$(grep "$i_relleno" $POKEDEX_FILE | cut -d '=' -f 2)
    TIPOS_POKEMON[$i]=$(grep "$i_relleno" $TIPOS_FILE | cut -d '=' -f 2)
  done
}

function menuPrincipal {
  while true; do
    # TODO: hacer algunas comprobaciones de archivos, configuración...
    # y mostrar por pantalla si hay algún problema (falta algo).
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
        guardarConfig;;
      "P")
        local esOpcionValida=true
        # TODO: No dejar elegir un pokémon que no existe.
        read -p "Introduce tu pokemon elegido: " POKEMON_JUGADOR
        guardarConfig;;
      "V")
        local esOpcionValida=true
        # TODO: Asegurarse de que victorias es un número.
        read -p "Introduce el número de victorias hasta el momento: " VICTORIAS
        guardarConfig;;
      "L")
        local esOpcionValida=true
        # TODO: Dar error si la nueva ubicación es incorrecta
        read -p "Introduce la nueva ubicación del fichero de log: " LOG_FILE
        guardarConfig;;
      "A")
        local esOpcionValida=true
        return;;
      *) 
        echo "Opción incorrecta";;
    esac
  done
}

function buscarNumPoke {
  for i in "${!NOMBRES_POKEMON[@]}"; do
    if [[ "${NOMBRES_POKEMON[$i]}" = "$1" ]]; then
        echo "${i}"
        break
    fi
  done
}

function mJugar {
  # Choose pokemons 
  n_jug=$(buscarNumPoke $POKEMON_JUGADOR)
  n_enem=$(randRange 0 151)
  poke_enem=${NOMBRES_POKEMON[$n_enem]}

  printf "${POKEMON_JUGADOR} vs. ${poke_enem}\n\n"

  # Sleep for intensity
  printf "${POKEMON_JUGADOR} pelea contra ${poke_enem}"
  sleeps=$(randRange 2 6)
  for i in $(seq 0 $sleeps)
  do
    printf '.'
    
    sleep 1
  done

  # Check who wins
  tipo_jug=${TIPOS_POKEMON[$n_jug]}
  tipo_enem=$(echo ${TIPOS_POKEMON[$n_enem]} | cut -b -2)

  linea_tipo=${TABLA_TIPOS[$tipo_jug]}
  # Si el tipo del enemigo está en la parte de la izquierda de la línea de la tabla
  # de tipos correspondiente al tipo del pokemon del jugador (con el formato que hemos 
  # puesto), el enemigo ha ganado, si está en la derecha el enemigo ha perdido
  if echo $linea_tipo | cut -d '-' -f 1 | grep -q "$tipo_enem"; then
    # Player wins
    echo "Gana!" 
    log $NOMBRE_JUGADOR ${POKEMON_JUGADOR} ${poke_enem} "Jugador"
    VICTORIAS=$(($VICTORIAS + 1))
    guardarConfig
  elif echo $linea_tipo | cut -d '-' -f 2 | grep -q "$tipo_enem"; then
    # Enemy wins
    echo "Pierde!"
    log $NOMBRE_JUGADOR ${POKEMON_JUGADOR} ${poke_enem} "Rival"
  else
    # Draw
    echo "Empate!"
    log $NOMBRE_JUGADOR ${POKEMON_JUGADOR} ${poke_enem} "Empate"
  fi
}

# Función: maxDicc <diccionario>
# Devuelve la llave que tiene el valor máximo dentro de un diccionario
function maxDicc {
  local -n dicc=$1

  max_key="Ninguno"
  max_val=0

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
  guardarConfig
}

function mSalir {
  exit 0
}

# Función: log <jugador> <pokemonJugador> <pokemonRival> <ganadorPartida>
# Guarda los datos introducidos, la fecha y la hora en el fichero log siguiendo
# el formato indicado en el enunciado del ejercicio.
function log {
  fecha=$(date +%d/%m/%Y)
  hora=$(date +%H:%M) 
  echo "$fecha | $hora | $1 | $2 | $3 | $4 | $5" >> $LOG_FILE
}

# Función: randRange <min> <max>
# Genera un número entero aleatorio en [min, max)
function randRange {
  local min=$1
  local max=$2
  echo $((min + $RANDOM % (max - min)))
}

if [ $# -eq 0 ]; then
  # programa
  echo "Cargando pokémon..."
  leerPokes
  cargarConfig
  menuPrincipal
elif [[ $# -eq 1 && "$1" == "-g" ]]; then
  # nuestros nombres
  echo "Grupo compuesto por:"
  echo "Pablo Pérez Rodríguez (712122549H) <pab@usal.es>"
  echo "Alberto Luengo Román  (09093933D) <luengor@usal.es>"
  exit 0
else
  echo "ERROR: Argumentos introducidos inválidos."
  usage
fi
