#!/usr/bin/env bash

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
AVISOCOLOR="\033[33m"

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
  printf "%bERROR: %b%b\n" "$ERRCOLOR" "$1" "$FINCOLOR" >&2
}
# Funcion: piso
# Print avISO
# Imprime una cadena de texto formateada con el color de aviso
function piso {
  printf "%bAVISO: %b%b\n" "$AVISOCOLOR" "$1" "$FINCOLOR" >&2
}
# Funcion: pgood
# Print GOOD
# Imprime una cadena de texto formateada con el color de ok 
function pgood {
  printf "%b%b%b\n" "$OKCOLOR" "$1" "$FINCOLOR"
}

# Función: comprobarArchivoRW <archivo> <nombre del fichero> <errorSiNoExiste>
# Comprueba que un archivo exista y se pueda escribir.
# Devuelve 0 si el archivo existe y se puede escribir, 1 si si existe pero 
# no tiene las cualidades necesarias para poderse leer y escribir, 
# y 2 si no existe.
# Si el archivo no existe y errorSiNoExiste es 0, imprime un mensaje de error,
# si es 1, imprime un mensaje de aviso.
function comprobarArchivoRW {
  if [[ -d "$1" ]]; then
    perro "$2 existe pero es un directorio."
    return 1
  fi
  if ! [[ -f "$1" ]]; then
    if $3; then
      perro "$2 no existe."
    else
      piso "$2 no existe."
    fi
    return 2
  fi
  if ! [[ -w $1 ]]; then
    # Si no existe, lo creamos o salimos si no es posible
    perro "¡$2 carece del permiso de escritura!" 
    return 1
  fi
  if ! [[ -r $1 ]]; then
    # Si no existe, lo creamos o salimos si no es posible
    perro "¡$2 carece del permiso de lectura!" 
    return 1
  fi
}


# Función: cargarConfig
# Esta función asume que el fichero config.cfg contiene sólo una de cada clave. 
function cargarConfig {
  # Comprobamos que existe el archivo de configuración
  local resultadoComprobarArchivo
  comprobarArchivoRW "$CONFIG_FILE" "El archivo de configuración" true
  resultadoComprobarArchivo=$?
  if [[ "$resultadoComprobarArchivo" -eq 1 ]]; then
    exit 1
  fi
  if [[ "$resultadoComprobarArchivo" -eq 2 ]]; then
    guardarConfig
    pgood "Se ha creado el archivo de configuración con los valores por defecto."
  fi
  

  # Cargamos los valores del archivo de configuración
  LOG_FILE=$(grep '^LOG=' "$CONFIG_FILE" | sed -e 's/LOG=//')

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
# Sale del programa si ha habido algún error al escribir la configuración.
function guardarConfig {
  if ! printf "NOMBRE=%s\nPOKEMON=%s\nVICTORIAS=%s\nLOG=%s\n" "$NOMBRE_JUGADOR" "$POKEMON_JUGADOR" "$VICTORIAS" "$LOG_FILE" > "$CONFIG_FILE"; then
    perro "No se pudo guardar la configuración."
    exit 1
  fi
}

# Función: leerPokes
# Lee los pokemon y los tipos de sus respectivos archivos, y los almacena en dos
# listas globales, 'NOMBRES_POKEMON' y 'TIPOS_POKEMON'. 
declare -a NOMBRES_POKEMON 
declare -a TIPOS_POKEMON
function leerPokes {
  # Comprobamos primero que el archivo "pokedex.cfg" existe y se puede leer 
  if ! [[ -r $POKEDEX_FILE ]]; then
    perro "¡El archivo \"${POKEDEX_FILE}\" no existe o carece de los permisos necesarios!"
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

# Función: leerSprites
# Lee los sprites y los guarda en una variable.
declare -A SPRITES_POKEMON
function leerSprites {
  # Comprobamos primero que el archivo "pokedex.cfg" existe y se puede leer 
  if ! [[ -r $SPRITES_FILE ]]; then
    perro "¡El archivo \"${SPRITES_FILE}\" no existe o carece de los permisos necesarios!"
    exit 1
  fi

  # Cada sprite tiene un tamaño de 32x32 caracteres, es decir, ocupa 32 líneas.
  # i: el número de la línea
  # poke_index: el número del pokemon
  # poke_subindex: el número de la línea dentro del pokemon 
  local poke_index
  local poke_subindex
  local i=0
  while IFS= read -r line; do
    poke_index=$((i / 32))
    poke_subindex=$((i % 32))
  
    SPRITES_POKEMON["$poke_index,$poke_subindex"]+="$line"
    i=$((i+1))
  done < "$SPRITES_FILE"
}

# Función: menuPrincipal
# Muestra el menú principal.
function menuPrincipal {
  while true; do
    echo ""
    echo "C) CONFIGURACION"
    echo "J) JUGAR"
    echo "E) ESTADÍSTICAS"
    echo "R) REINICIO"
    echo "S) SALIR"
    read -rp ' "POKÉMON EDICION USAL". Introduzca una opción >>' opcion
    case ${opcion^^} in
      "C")
        mConfig;;
      "J")
        if comprobarJugar; then
          mJugar
        else 
          perro "¡No puedes jugar hasta que no corrijas los errores!"
        fi;;
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

# Función: existeEnLista <elemento> <lista>
# Comprueba si un elemento está en una lista.
function existeEnLista {
  local -n arr=$2
  for i in "${arr[@]}"; do
    if [[ "$i" == "$1" ]]; then
      return 0 # true
    fi
  done
  return 1 # false
}

# Función: mConfig
# Muestra el menú de configuración, que permite la modificación de los valores
# que hay dentro del archivo de configuración.
function mConfig {
  # El menú de configuración no desaparecerá hasta que se introduzca
  # una opcion correcta
  local volverAMostrar=true

  while $volverAMostrar; do
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
        read -rp "Introduce tu nombre de jugador: " NOMBRE_JUGADOR
        guardarConfig;;

      # Cambiar pokemon 
      "P")
        read -rp "Introduce tu pokémon elegido: " nuevo_pokemon 
        # Hacemos que el nombre esté escrito con la primera letra en mayúscula,
        # y el resto en minúscula. Así está escrito de la misma forma que los
        # nombres de los pokemon en el archivo "pokedex.cfg".
        nuevo_pokemon="${nuevo_pokemon,,}"
        nuevo_pokemon="${nuevo_pokemon^}"

        # Comprobamos si el nombre está en la lista
        if existeEnLista "$nuevo_pokemon" NOMBRES_POKEMON; then
          if [[ -z "$POKEMON_JUGADOR" ]]; then
            pgood "¡Hola $nuevo_pokemon!"
          elif [[ "$nuevo_pokemon" == "$POKEMON_JUGADOR" ]]; then
            pgood "¡$POKEMON_JUGADOR ya era tu pokémon!"
          else
            pgood "¡Adiós $POKEMON_JUGADOR, hola $nuevo_pokemon!"
          fi

          POKEMON_JUGADOR=$nuevo_pokemon
          guardarConfig
        else
          perro "¡Ese pokémon no existe! No se ha cambiado el pokémon"
        fi;;

      # Cambiar número de victorias
      "V")
        read -rp "Introduce el número de victorias hasta el momento: " nuevas_victorias 

        # Comprobar que lo introducido es un número
        if [[ "$nuevas_victorias" =~ ^[0-9]+$ ]]; then
          pgood "¡Número de victorias modificado!"

          VICTORIAS=$nuevas_victorias
          guardarConfig
        else
          perro "¡El número de victorias debe ser un número!" 
        fi;;

      # Cambiar fichero de logs
      "L")
        read -rp "Introduce la nueva ubicación del fichero de log: " nuevo_fichero
        local resultadoComprobarArchivo
        comprobarArchivoRW "$nuevo_fichero" "El fichero" true
        resultadoComprobarArchivo=$?
        if [[ "$resultadoComprobarArchivo" -eq 1 ]]; then
          # ComprobarArchivoRW ya ha mostrado el error
          :
        elif [[ "$resultadoComprobarArchivo" -eq 2 ]]; then
          if (printf "" > "$nuevo_fichero") 2> /dev/null; then
            pgood "¡Fichero de logs creado!"

            LOG_FILE=$nuevo_fichero
            guardarConfig
          else
            perro "¡No se pudo crear el fichero!"
          fi
        else
          pgood "¡Fichero de logs establecido!"

          LOG_FILE=$nuevo_fichero
          guardarConfig
        fi;;
      # Salir del menú
      "A")
        volverAMostrar=false
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
  local var=$1
  local longitud="${#var}"
  local inv=""

  for (( i=longitud; i >= 0; i-- )); do 
    inv+="${var:$i:1}"
  done

  echo "$inv"
}

# Función: impirmirDibujosNum <num pokemon izq> <num pokemon dcha>
# Dibuja dos pokemon, frente a frente, como si estuvieran peleando.
function impirmirDibujosNum {
  local poke_color1=${TABLA_COLORES[${TIPOS_POKEMON[$1]}]}
  local poke_color2=${TABLA_COLORES[${TIPOS_POKEMON[$2]}]}

  # Para que quede bonito, añadimos espacios, así la anchura del resultado
  # final es la misma que la del terminal (80, el valor por defecto).
  # [poke1(32)][espacio(16)][poke2(32)]

  # %16s y luego pasarle "" como string es una forma de hacer que
  # printf imprima 16 espacios.

  # Iteramos de 0 a 31 porque los sprites tienen tamaño 32 líneas x 32 columnas.
  for i in {0..31}; do
    printf "%b%s%16s%b%s\n" "$poke_color1" "${SPRITES_POKEMON[$1,$i]}" "" "$poke_color2" "$(invertirCadena "${SPRITES_POKEMON[$2,$i]}")"
  done

  # para que no esté todo cambiado de color, pasamos el color neutro
  printf "%b" "$FINCOLOR" 
}

# Función: comprobarJugar 
# Comprueba que el usuario tenga un nombre, que el nombre del pokémon sea
# correcto...
function comprobarJugar {
  local valorRetorno=0

  if [[ -z "$NOMBRE_JUGADOR" ]]; then
    perro "¡No tienes un nombre!"
    valorRetorno=1
  fi
  if [[ -z "$POKEMON_JUGADOR" ]]; then
    perro "¡No tienes un pokémon!"
    valorRetorno=1
  elif ! existeEnLista "$POKEMON_JUGADOR" NOMBRES_POKEMON; then
    perro "¡El pokémon '$POKEMON_JUGADOR' no existe!"
    valorRetorno=1
  fi
  if ! [[ "$VICTORIAS" =~ ^[0-9]+$ ]]; then
    perro "El valor de victorias en la configuración no es un número."
    valorRetorno=1
  fi
  return $valorRetorno
}

# Función: imprimirTextoCentrado <texto> <ancho>
# Imprime texto centrado en un bloque del ancho especificado en el segundo
# argumento.
# Ejemplo: imprimirTextoCentrado "test" 10 => "   test   "
function imprimirTextoCentrado {
  local pad_delante="$((($2 - ${#1}) / 2))"
  local pad_detras=$(($2 - pad_delante - ${#1}))
  printf "%*s%s%*s\n" "$pad_delante" "" "$1" "$pad_detras" ""
}

# Función: mJugar
# Muestra el menú de juego. Esta es la función más importante.
function mJugar {
  # Choose pokemons 
  local n_jug=$(buscarNumPoke "$POKEMON_JUGADOR")
  local n_enem=$(randRange 0 151)
  local poke_enem=${NOMBRES_POKEMON[$n_enem]}

  impirmirDibujosNum "$n_jug" "$n_enem"
  printf "%s%16s%s\n" "$(imprimirTextoCentrado "$POKEMON_JUGADOR" 32)" "" "$(imprimirTextoCentrado "$poke_enem" 32)"

  printf "%s pelea contra %s" "$POKEMON_JUGADOR" "$poke_enem"
  # No podemos utilizar un for in {0..$sleeps..1} porque se evalúa el {} antes
  # que el $sleeps, haciendo que la iteración no funcione (itera desde cero)
  # hasta una cadena de caracteres.
  local sleeps=$(randRange 2 6)
  for (( i=0; i<=sleeps; i++ )); do
    printf '.'
    
    sleep 1
  done
  printf "\n"

  # Comprobar quién gana
  local tipo_jug=${TIPOS_POKEMON[$n_jug]}
  local tipo_enem=$(echo "${TIPOS_POKEMON[$n_enem]}" | cut -b -2)
  local linea_tipo=${TABLA_TIPOS[$tipo_jug]}

  # Si el tipo del enemigo está en la parte de la izquierda de la línea de la tabla
  # de tipos correspondiente al tipo del pokemon del jugador (con el formato que hemos 
  # puesto), el enemigo ha ganado, si está en la derecha el enemigo ha perdido
  if echo "$linea_tipo" | cut -d '-' -f 1 | grep -q "$tipo_enem"; then
    # El jugador gana
    echo "¡$POKEMON_JUGADOR ha vencido a $poke_enem!" 
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Jugador"
    VICTORIAS=$((VICTORIAS + 1))
    guardarConfig
  elif echo "$linea_tipo" | cut -d '-' -f 2 | grep -q "$tipo_enem"; then
    # El enemigo gana
    echo "¡$POKEMON_JUGADOR ha perdido contra $poke_enem!" 
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Rival"
  else
    # Empate
    echo "$POKEMON_JUGADOR y $poke_enem son igual de poderosos. ¡Empate!" 
    log "$NOMBRE_JUGADOR" "${POKEMON_JUGADOR}" "${poke_enem}" "Empate"
  fi
}

# Función: maxDicc <diccionario>
# Devuelve la llave que tiene el valor máximo dentro de un diccionario.
function maxDicc {
  local -n dicc=$1

  local max_key="Ninguno"
  local max_val=0

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
  local resultadoComprobarArchivo
  comprobarArchivoRW "$LOG_FILE" "El fichero de log" true
  resultadoComprobarArchivo=$?
  if [[ $resultadoComprobarArchivo -ne 0 ]]; then
    return
  fi

  local ncombates=0
  local nganados=0
  declare -A poke_ganados_jugador
  declare -A poke_ganados_rival

  while read -r line; do
    local ncombates=$((ncombates+1))

    # Comprobamos ganador
    local ganador=$(cut -d '|' -f 6 <<< "$line" | cut -b 2)
    case $ganador in
      'J')
        nganados=$((nganados+1))

        # Nombre del pokemon ganador
        local poke_nombre=$(echo "$line" | cut -d'|' -f4)

        # Hay que comprobar que el valor ya está en el array antes de incrementarlo
        if [[ -v poke_ganados_jugador[$poke_nombre] ]]; then
          poke_ganados_jugador[$poke_nombre]=$((${poke_ganados_jugador[$poke_nombre]} + 1))
        else
          poke_ganados_jugador[$poke_nombre]=1
        fi
        ;;

      'R')
        # Nombre del pokemon ganador
        local poke_nombre=$(echo "$line" | cut -d'|' -f5)

        # Hay que comprobar que el valor ya está en el array antes de incrementarlo
        if [[ -v poke_ganados_rival[$poke_nombre] ]]; then
          poke_ganados_rival[$poke_nombre]=$((${poke_ganados_rival[$poke_nombre]} + 1))
        else
          poke_ganados_rival[$poke_nombre]=1
        fi
        ;;
    esac
  done < "$LOG_FILE"

  # Calculamos los pokemons con más victorias
  local max_pgj=$(maxDicc poke_ganados_jugador)
  local max_pgr=$(maxDicc poke_ganados_rival)

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
  if [[ -n $LOG_FILE ]]; then
    if ! echo "" > "$LOG_FILE"; then
      perro "Error al vaciar el archivo de log\n"
    fi
  fi

  # Cambiar las configuraciones
  NOMBRE_JUGADOR=""
  POKEMON_JUGADOR=""
  VICTORIAS=""
  # No vaciamos la variable LOG_FILE porque es más cómodo para el usuario no tener que
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
  if [[ -z $LOG_FILE ]]; then
    piso "No se ha almacenado la partida en el fichero de log, porque no se ha proporcionado uno"
    return
  fi
  
  local resultadoComprobarArchivo
  comprobarArchivoRW "$LOG_FILE" "El fichero de log" false
  resultadoComprobarArchivo=$?
  if [[ $resultadoComprobarArchivo -eq 2 ]]; then
    piso "Se va a intentar crear el fichero de log"
  fi

  if [[ "$resultadoComprobarArchivo" -eq 0 || "$resultadoComprobarArchivo" -eq 2 ]]; then
    local fecha=$(date +%d/%m/%Y)
    local hora=$(date +%H:%M) 
    if ! echo "$fecha | $hora | $1 | $2 | $3 | $4" >> "$LOG_FILE"; then
      perro "No se ha podido guardar la partida en el fichero de log"
    else
      pgood "Se ha guardado esta partida en el fichero de log"
    fi
  else
    perro "No se ha podido guardar la partida en el fichero de log"
  fi
}

# Función: randRange <min> <max>
# Genera un número entero aleatorio en [min, max).
function randRange {
  local min=$1
  local max=$2
  echo $((min + RANDOM % (max - min)))
}

if [[ $# -eq 0 ]]; then
  # programa
  echo "Cargando pokémon..."
  leerPokes
  printf "\033[95mCargando imágenes bonitas...%b\n" "$FINCOLOR"
  leerSprites
  echo "Cargando configuración..."
  cargarConfig
  menuPrincipal
elif [[ $# -eq 1 && "$1" == "-g" ]]; then
  # nuestros nombres
  echo "Grupo compuesto por:"
  printf "\033[33m***NAME REDACTED*** (***ID REDACTED***) <***EMAIL REDACTED***>\n%b" "$FINCOLOR"
  printf "\033[31m***NAME REDACTED***  (***ID REDACTED***) <***EMAIL REDACTED***>\n%b" "$FINCOLOR"
  exit 0
else
  perro "Argumentos introducidos inválidos."
  uso
fi

