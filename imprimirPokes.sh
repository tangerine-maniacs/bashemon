#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# TODO: Quitar esto antes de hacer la defensa
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

POKEDEX_FILE="pokedex.cfg"
TIPOS_FILE="tipos.cfg"
CONFIG_FILE="config.cfg"

FINCOLOR="\e[0m"

declare -A TABLA_COLORES=(
  ["normal"]="\e97m"
  ["lucha"]=""
  ["volador"]="\e97m"
  ["veneno"]="\e32m"
  ["tierra"]=""
  ["roca"]=""
  ["bicho"]=""
  ["fantasma"]=""
  ["fuego"]="\e[31m"
  ["agua"]="\e34m"
  ["planta"]="\e92m"
  ["electrico"]="\e33m"
  ["psiquico"]=""
  ["hielo"]=""
  ["dragon"]="\e35m"
)

# Imprimir dibujo pokemon empieza en 0
function impirmirDibujoNum {
  local poke_number=$1

  local i
  local pokei
  i=0
  pokei=0
  while IFS= read line; do
    i=$((i+1))
    poken=$((i/32))
    
    if [[ "$poken" < "$poke_number" ]]; then
      continue
    elif [[ "$poken" > "$poke_number" ]]; then
      break
    fi

    echo "$line"
  done < smallsprites.txt
}

function invertirCadena {
  local var
  local longitud
  local i
  local inv
  var=$1
  longitud="${#var}"
  inv=""

  for (( i=$longitud; i >= 0; i-- )); do 
    inv+="${var:$i:1}"
  done

  echo "$inv"
}

# repetir <texto> <numero>
function repetir {
  for (( i=0; i < "$2"; i++ )); do 
    printf "$1"
  done
}

function impirmirDibujosNum {
  local poke_number1
  local poke_number2
  poke_number1=$1
  poke_number2=$2

  declare -a arr_poke1
  declare -a arr_poke2

  # i: el número de la línea
  # poke_index: el número del pokemon
  # poke_subindex: el número de la línea dentro del pokemon 
  local i
  local poke_index
  local poke_subindex
  i=0

  while IFS= read line; do
    poke_index=$((i / 32))
    poke_subindex=$((i % 32))
  
    # No ponemos elif porque poke_number1 y poke_number2 pueden ser iguales y
    # si tuviera un elif, sólo añadiríamos el texto del primer pokemon.
    if [[ $poke_index = $poke_number1 ]]; then
      arr_poke1[poke_subindex]+="$line"
    fi
    if [[ $poke_index = $poke_number2 ]]; then
      arr_poke2[poke_subindex]+=$(invertirCadena "$line")
    fi

    # Cuando hayamos pasado todos los pokemon que queremos imprimir, salir.
    if [[ $poke_index -gt $poke_number1 && $poke_index -gt $poke_number2 ]]; then
      break
    fi
    i=$((i+1))
  done < smallsprites.txt

  # Para que quede bonito, añado espacios, así la anchura del resultado
  # final es la misma que la del terminal (80 por defecto).
  # [poke1(32)][espacio(16)][poke2(32)]
  for i in "${!arr_poke1[@]}"; do
     echo "${arr_poke1[$i]}$(repetir ' ' 16)${arr_poke2[$i]}"
  done
}

# imprimirTextoCentrado <texto> <ancho>
function imprimirTextoCentrado {
  local pad_delante
  pad_delante="$(((${#1} + $2) / 2))"
  pad_detras=$(($2 - pad_delante - ${#1}))
  printf "%*s%*s\n" "$pad_delante" "$1" "$pad_detras" ""
}


impirmirDibujosNum 10 2
echo "$(imprimirTextoCentrado 'aa' 32)$(repetir ' ' 16)$(imprimirTextoCentrado 'aab' 32)"
