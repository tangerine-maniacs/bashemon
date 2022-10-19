#!/usr/bin/env bash

POKEDEX_FILE="pokedex.cfg"
TIPOS_FILE="tipos.cfg"
CONFIG_FILE="config.cfg"

function usage() {
  echo "Bashémon: Proyecto SSOOI"
  echo "Uso: $0 [-g]"
  echo " -g: Mostrar los nombres de los integrantes del equipo"
  exit 1
}

function readCfg() {
  :
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
  :
}

function mEstadisticas() {
  :
}

function mReinicio() {
  :
}

function mSalir() {
  exit 0
}
function log() {
  :
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
