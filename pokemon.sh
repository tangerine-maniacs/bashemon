#!/usr/bin/env bash

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

function randRange() {
  :
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
  echo "Pablo Pérez Rodríguez (712122549H) <pab@usal.es>"
  echo "Alberto Luengo Román  (09093933D) <luengor@usal.es>"
  exit 0
else
  echo "ERROR: Argumentos introducidos inválidos."
  usage
fi
