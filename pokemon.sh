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

function mainMenu() {
  :
}

function configMenu() {
  :
}

function play() {
  :
}

function statsMenu() {
  :
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
  echo $((min + RANDOM % (max - min)))
}

function loadCoolPokegraphics() {
  :
}
function coolGraphics() {
  :
}

if [ $# -eq 0 ]; then
  # programa
  :
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
