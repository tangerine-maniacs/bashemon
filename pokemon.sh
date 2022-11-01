#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o noglob

# TODO: Quitar esto antes de hacer la defensa
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# /usr/bin no sigue las normas POSIX :)
# Así que vamos a añadir /usr/xpg4/bin al PATH
# Lo ponemos dentro de un if para poder ejecutar el código en otras máquinas
# que no sean Solaris.
if [[ "$(hostname)" = "encina" ]]; then
  export PATH="/usr/xpg4/bin:$PATH"
fi

# === CONSTANTES ===
POKEDEX_FILE="pokedex.cfg"
TIPOS_FILE="tipos.cfg"
CONFIG_FILE="config.cfg"
SPRITES_FILE="smallsprites.txt"

# la tabla está mal 100% seguro
# pero no lo puedo demostrar
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

FINCOLOR="\033[0m"
ERRCOLOR="\033[91m"
OKCOLOR="\033[92m"

declare -A TABLA_COLORES=(
  ["normal"]="\033[97m"
  ["lucha"]="\033[31m"
  ["volador"]="\033[42"
  ["veneno"]="\033[35m"
  ["tierra"]=$FINCOLOR
  ["roca"]=$FINCOLOR
  ["bicho"]=$FINCOLOR
  ["fantasma"]=$FINCOLOR
  ["fuego"]="\033[91m"
  ["agua"]="\033[34m"
  ["planta"]="\033[92m"
  ["electrico"]="\033[33m"
  ["psiquico"]="\033[95m"
  ["hielo"]=$FINCOLOR
  ["dragon"]="\033[35m"
)

# === config.cfg === 
# Valores cargados de config.cfg
LOG_FILE=""
NOMBRE_JUGADOR=""
VICTORIAS=""
POKEMON_JUGADOR=""

# === funciones ===
# Función: uso
# Imprime cómo usar el script (argumentos), y devuelve 0 (ejecución 
# satisfactoria).
function uso {
  echo "Bashémon: Proyecto SSOOI"
  echo "Uso: $0 [-g]"
  echo " -g: Mostrar los nombres de los integrantes del equipo"
  exit 0
}

# Funcion: perro
# Print ERROr 
# Imprime una cadena de texto formateada con el color de error
function perro {
  printf "%b%b%b" "$ERRCOLOR" "$1" "$FINCOLOR"
}


# Funcion: pgood
# Print GOOD
# Imprime una cadena de texto formateada con el color de ok 
function pgood {
  printf "%b%b%b" "$OKCOLOR" "$1" "$FINCOLOR"
}


# Esta función asume que el fichero config.cfg incluye esas claves, sólo esas 
# claves y sólo una de cada.
function cargarConfig {
  # Comprobamos que existe el archivo de configuración
  if ! [ -w $CONFIG_FILE ]; then
    # Si no existe, lo creamos o salimos si no es posible
    perro "¡El archivo \"config.cfg\" no existe o carece de los permisos necesarios!\n" 

    newfile="NOMBRE=Nombre jugador\nPOKEMON=Bulbasaur\nVICTORIAS=0\nLOG=info.log"

    if (echo -e "$newfile" > "config.cfg") 2> /dev/null; then
      printf " ¡Archivo de configuración creado!\n"
    else
      perro "¡No se pudo crear el archivo de configuración!\n"
      exit 1
    fi
  fi

  LOG_FILE=$(grep '^LOG=' "$CONFIG_FILE" | sed -e 's/LOG=//')
  if [[ -z "$LOG_FILE" ]]; then
    return 1
  fi

  VICTORIAS=$(grep '^VICTORIAS=' "$CONFIG_FILE" | sed -e 's/VICTORIAS=//')
  if [[ -z "$VICTORIAS" ]]; then
    VICTORIAS=0 # victorias va a ser 0 por defecto (si no existe)
  fi

  NOMBRE_JUGADOR=$(grep '^NOMBRE=' "$CONFIG_FILE" | sed -e 's/NOMBRE=//')
  POKEMON_JUGADOR=$(grep '^POKEMON=' "$CONFIG_FILE" | sed -e 's/POKEMON=//')
}

# Función: guardarConfig
# Genera un archivo de configuración y lo guarda, basándose en los valores de 
# las variables globales (declaradas en la sección 'config.cfg').
function guardarConfig {
  printf "NOMBRE=%s\nPOKEMON=%s\nVICTORIAS=%s\nLOG=%s\n" "$NOMBRE_JUGADOR" "$POKEMON_JUGADOR" "$VICTORIAS" "$LOG_FILE" > "$CONFIG_FILE"
}

# Función: leerPokes
# Lee los pokemon y los tipos de sus respectivos archivos, y los almacena en dos
# listas globales, 'NOMBRES_POKEMON' y 'TIPOS_POKEMON'. 
declare -a NOMBRES_POKEMON 
declare -a TIPOS_POKEMON
function leerPokes {
  # Comprobamos primero que el archivo "pokedex.cfg" existe y se puede leer 
  if ! [ -r $POKEDEX_FILE ]; then
    perro "¡El archivo \"pokedex.cfg\" no existe o carece de los permisos necesarios!\n"
    exit 1
  fi

  # Para leer los pokemon en orden (en caso de que el archivo tenga alguna 
  # línea desordenada) generamos los números de las líneas (rellenando con 0s a
  # la izquierda) y leemos las líneas que tienen esos números.
  for i in {0..150..1}; do
    i_relleno=$(printf "%03d" "$((i+1))")
    NOMBRES_POKEMON[$i]=$(grep "$i_relleno" $POKEDEX_FILE | cut -d '=' -f 2)
    TIPOS_POKEMON[$i]=$(grep "$i_relleno" $TIPOS_FILE | cut -d '=' -f 2)
  done
}

# Función: menuPrincipal
# Muestra el menú principal.
function menuPrincipal {
  while true; do
    # TODO: hacer algunas comprobaciones de archivos, configuración...
    # y mostrar por pantalla si hay algún problema (falta algo).
    echo ""
    echo "C) CONFIGURACION"
    echo "J) JUGAR"
    echo "E) ESTADÍSTICAS"
    echo "R) REINICIO"
    echo "S) SALIR"
    read -rp ' "POKEMON EDICION USAL". Introduzca una opción >>' opcion
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

# Función: mConfig
# Muestra el menú de configuración, que permite la modificación de los valores
# que hay dentro del archivo de configuración.
function mConfig {
  # El menú de configuración no desaparecerá hasta que se introduzca
  # una opcion correcta
  local esOpcionValida=false

  while ! $esOpcionValida; do
    echo ""
    echo "N) CAMBIAR NOMBRE DEL JUGADOR          (Actual: ${NOMBRE_JUGADOR})"
    echo "P) CAMBIAR POKÉMON ELEGIDO             (Actual: ${POKEMON_JUGADOR})"
    echo "V) CAMBIAR Nº VICTORIAS                (Actual: ${VICTORIAS})"
    echo "L) CAMBIAR UBICACIÓN DE FICHERO DE LOG (Actual: ${LOG_FILE})"
    echo "A) ATRÁS"
    read -rp ' ¿Qué desea hacer? >>' opcion

    case ${opcion^^} in
      # Cambiar nombre
      "N")
        local esOpcionValida=true
        read -rp "Introduce tu nombre de jugador: " NOMBRE_JUGADOR
        guardarConfig;;

      # Cambiar pokemon 
      "P")
        read -rp "Introduce tu pokemon elegido: " nuevo_pokemon 

        # Comprobamos si el nombre está en la lista
        if echo "${NOMBRES_POKEMON[@]}" | grep -q " ${nuevo_pokemon// /}"; then
          local esOpcionValida=true
          pgood "¡Adiós $POKEMON_JUGADOR, hola $nuevo_pokemon!\n"

          POKEMON_JUGADOR=$nuevo_pokemon
          guardarConfig
        else
          local esOpcionValida=false
          perro "¡Ese pokemon no existe!\n"
        fi;;

      # Cambiar número de victorias
      "V")
        read -rp "Introduce el número de victorias hasta el momento: " nuevas_victorias 

        # Comprobar que lo introducido es un número
        if [[ "$nuevas_victorias" =~ ^[0-9]+$ ]]; then
          local esOpcionValida=true
          pgood "¡Número de victorias modificado!\n"

          NOMBRE_JUGADOR=$nuevas_victorias
          guardarConfig
        else
          local esOpcionValida=false
          perro "¡El número de victorias debe ser un número!\n" 
        fi;;

      # Cambiar fichero de logs
      "L")
        read -rp "Introduce la nueva ubicación del fichero de log: " nuevo_fichero

        # Comprueba si es un fichero
        if [[ -f $nuevo_fichero ]]; then
          # Si lo es, comprobamos que es modificable
          if [[ -w $nuevo_fichero ]]; then
            local esOpcionValida=true
            pgood "¡Fichero de logs establecido!\n"

            LOG_FILE=$nuevo_fichero
            guardarConfig
          else
            local esOpcionValida=false
            perro "¡No se puede modificar ese fichero!\n"
          fi

        # Comprobamos si es un directorio
        elif [[ -d $nuevo_fichero ]]; then
          local esOpcionValida=false
          perro "¡Eso no es un archivo!\n"

        # Si no es ni un directorio, ni un fichero, lo intentamos crear
        else
          if (echo "" > "$nuevo_fichero") 2> /dev/null; then
            local esOpcionValida=true
            pgood "¡Fichero de logs creado!\n"

            LOG_FILE=$nuevo_fichero
            guardarConfig
          else
            local esOpcionValida=false
            perro "¡No se pudo crear el archivo!\n"
          fi
        fi;;

      # Salir del menú
      "A")
        local esOpcionValida=true
        return;;
      *) 
        perro "Opción incorrecta\n";;
    esac
  done
}

# Función: buscarNumPoke <nombre del pokemon>
# Busca en la lista de NOMBRES_POKEMON el índice del pokemon pasado.
# como argumento.
function buscarNumPoke {
  for i in "${!NOMBRES_POKEMON[@]}"; do
    if [[ "${NOMBRES_POKEMON[$i]}" = "$1" ]]; then
        echo "${i}"
        break
    fi
  done
}

# Función: invertirCadena <cadena>
# Devuelve la cadena, invertida.
function invertirCadena {
  local var
  local longitud
  local inv
  var=$1
  longitud="${#var}"
  inv=""

  for (( i=longitud; i >= 0; i-- )); do 
    inv+="${var:$i:1}"
  done

  echo "$inv"
}

# Función: impirmirDibujosNum <num pokemon izq> <num pokemon dcha>
# Dibuja dos pokemon, frente a frente, como si estuvieran peleando.
function impirmirDibujosNum {
  local poke_number1
  local poke_number2
  poke_number1=$1
  poke_number2=$2

  poke_color1=${TABLA_COLORES[${TIPOS_POKEMON[$1]}]}
  poke_color2=${TABLA_COLORES[${TIPOS_POKEMON[$2]}]}

  declare -a arr_poke1
  declare -a arr_poke2

  # i: el número de la línea
  # poke_index: el número del pokemon
  # poke_subindex: el número de la línea dentro del pokemon 
  local poke_index
  local poke_subindex
  i=0

  while IFS= read -r line; do
    poke_index=$((i / 32))
    poke_subindex=$((i % 32))
  
    # No ponemos elif porque poke_number1 y poke_number2 pueden ser iguales y
    # si tuviera un elif, sólo añadiríamos el texto del primer pokemon.
    if [[ "$poke_index" -eq "$poke_number1" ]]; then
      arr_poke1[poke_subindex]+="$line"
    fi
    if [[ "$poke_index" -eq "$poke_number2" ]]; then
      # LOS CARACTERES SON DE 2 BYTES Y ENCINA LOS VOLTEA MAL
      arr_poke2[poke_subindex]+=$(invertirCadena "$line")
    fi

    # Cuando hayamos pasado todos los pokemon que queremos imprimir, salir.
    if [[ "$poke_index" -gt "$poke_number1" && "$poke_index" -gt "$poke_number2" ]]; then
      break
    fi
    i=$((i+1))
  done < "$SPRITES_FILE"

  # Para que quede bonito, añado espacios, así la anchura del resultado
  # final es la misma que la del terminal (80 por defecto).
  # [poke1(32)][espacio(16)][poke2(32)]

  # %16s y luego pasarle "" como string es una forma de hacer que
  # printf imprima 16 espacios
  # por alguna razón, printf no imprime las cadenas de color cuando
  # se le pasan como argumentos, por lo que hace falta imprimirlas
  # al argumento
  for i in "${!arr_poke1[@]}"; do
    printf "%b%s%16s%b%s\n" "$poke_color1" "${arr_poke1[$i]}" "" "$poke_color2" "${arr_poke2[$i]}"
  done

  # para que no esté todo cambiado de color, pasamos el color neutro
  printf "%b" "$FINCOLOR" 
}

# Función: imprimirTextoCentrado <texto> <ancho>
# Imprime texto centrado en un bloque del ancho especificado en el segundo
# argumento.
# Ejemplo: imprimirTextoCentrado "test" 10 => "   test   "
function imprimirTextoCentrado {
  pad_delante="$(((${#1} + $2) / 2))"
  pad_detras=$(($2 - pad_delante - ${#1}))
  printf "%*s%*s\n" "$pad_delante" "$1" "$pad_detras" ""
}

# Función: mJugar
# Muestra el menú de juego. Esta es la función más importante.
function mJugar {
  # Choose pokemons 
  n_jug=$(buscarNumPoke "$POKEMON_JUGADOR")
  n_enem=$(randRange 0 151)
  poke_enem=${NOMBRES_POKEMON[$n_enem]}

  impirmirDibujosNum "$n_jug" "$n_enem"
  printf "%s%16s%s\n" "$(imprimirTextoCentrado "$POKEMON_JUGADOR" 32)" "" "$(imprimirTextoCentrado "$poke_enem" 32)"

  # Sleep for intensity
  printf "%s pelea contra %s" "$POKEMON_JUGADOR" "$poke_enem"
  sleeps=$(randRange 2 6)
  # No podemos utilizar un for in {0..$sleeps..1} porque se evalúa el {} antes
  # que el $sleeps, haciendo que la iteración no funcione (itera desde cero)
  # hasta una cadena de caracteres.
  for (( i=0; i<=sleeps; i++ )); do
    printf '.'
    
    sleep 1
  done

  # Check who wins
  tipo_jug=${TIPOS_POKEMON[$n_jug]}
  tipo_enem=$(echo "${TIPOS_POKEMON[$n_enem]}" | cut -b -2)

  linea_tipo=${TABLA_TIPOS[$tipo_jug]}
  # Si el tipo del enemigo está en la parte de la izquierda de la línea de la tabla
  # de tipos correspondiente al tipo del pokemon del jugador (con el formato que hemos 
  # puesto), el enemigo ha ganado, si está en la derecha el enemigo ha perdido
  if echo "$linea_tipo" | cut -d '-' -f 1 | grep -q "$tipo_enem"; then
    # Player wins
    echo "Gana!" 
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Jugador"
    VICTORIAS=$((VICTORIAS + 1))
    guardarConfig
  elif echo "$linea_tipo" | cut -d '-' -f 2 | grep -q "$tipo_enem"; then
    # Enemy wins
    echo "Pierde!"
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Rival"
  else
    # Draw
    echo "Empate!"
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Empate"
  fi
}

# Función: maxDicc <diccionario>
# Devuelve la llave que tiene el valor máximo dentro de un diccionario.
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

  echo "$max_key" 
}

# Función: mEstadisticas
# Calcula las estadísticas a partir del archivo log, y posteriormente muestra el
# menú de estadísticas, 
function mEstadisticas {
  local ncombates=0
  local nganados=0
  declare -A poke_ganados_jugador
  declare -A poke_ganados_rival

  while read -r line; do
    ncombates=$((ncombates+1))

    # Comprobamos ganador
    ganador=$(cut -d '|' -f 6 <<< "$line" | cut -b 2)
    case $ganador in
      'J')
        nganados=$((nganados+1))

        # Nombre del pokemon ganador
        poke_nombre=$(echo "$line" | cut -d'|' -f4)

        # Hay que comprobar que el valor ya está en el array antes de incrementarlo
        if [[ -v poke_ganados_jugador[$poke_nombre] ]]; then
          poke_ganados_jugador[$poke_nombre]=$((${poke_ganados_jugador[$poke_nombre]} + 1))
        else
          poke_ganados_jugador[$poke_nombre]=1
        fi
        ;;

      'R')
        # Nombre del pokemon ganador
        poke_nombre=$(echo "$line" | cut -d'|' -f5)

        # Hay que comprobar que el valor ya está en el array antes de incrementarlo
        if [[ -v poke_ganados_rival[$poke_nombre] ]]; then
          poke_ganados_rival[$poke_nombre]=$((${poke_ganados_rival[$poke_nombre]} + 1))
        else
          poke_ganados_rival[$poke_nombre]=1
        fi
        ;;
    esac
  done < info.log

  # Calculamos los pokemons con más victorias
  max_pgj=$(maxDicc poke_ganados_jugador)
  max_pgr=$(maxDicc poke_ganados_rival)

  # Imprimimos la información
  echo "Número total de combates: $ncombates"
  echo "Número de combates ganados por el jugador: $nganados"

  # Hay que comprobar que se ha ganado por lo menos 1 vez para imprimir
  if [[ "$max_pgj" == "Ninguno" ]];then 
    echo "El jugador todavía no ha ganado ningún combate"
  else
    echo "Pokémon del jugador con más victorias (${poke_ganados_jugador[$max_pgj]}): $max_pgj"
  fi

  if [[ "$max_pgr" == "Ninguno" ]];then 
    echo "El rival todavía no ha ganado ningún combate"
  else
    echo "Pokémon del rival con más victorias (${poke_ganados_rival[$max_pgr]}): $max_pgr"
  fi
}

# Función: mReinicio
# Vacía el archivo de log, y los campos de config.cfg (excepto el campo de 
# ruta del archivo de log)
function mReinicio {
  # Vaciar el archivo log
  printf "" > "$LOG_FILE"

  # Cambiar las configuraciones
  NOMBRE_JUGADOR=""
  POKEMON_JUGADOR=""
  VICTORIAS=""
  # No vaciamos LOG_FILE porque es más cómodo para el usuario no tener que
  # volver a escribir la ruta
  guardarConfig
}

# Función: mSalir
# Sale del programa, poniendo el código 0.
function mSalir {
  exit 0
}

# Función: log <jugador> <pokemonJugador> <pokemonRival> <ganadorPartida>
# Guarda los datos introducidos, la fecha y la hora en el fichero log siguiendo
# el formato indicado en el enunciado del ejercicio.
function log {
  fecha=$(date +%d/%m/%Y)
  hora=$(date +%H:%M) 
  echo "$fecha | $hora | $1 | $2 | $3 | $4" >> "$LOG_FILE"
}

# Función: randRange <min> <max>
# Genera un número entero aleatorio en [min, max).
function randRange {
  local min=$1
  local max=$2
  echo $((min + RANDOM % (max - min)))
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
  printf "\033[33m***NAME REDACTED*** (***ID REDACTED***) <***EMAIL REDACTED***>\n%b" "$FINCOLOR"
  printf "\033[31m***NAME REDACTED***  (***ID REDACTED***) <***EMAIL REDACTED***>\n%b" "$FINCOLOR"
  exit 0
else
  echo "ERROR: Argumentos introducidos inválidos."
  uso
fi

