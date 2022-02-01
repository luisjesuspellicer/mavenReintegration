#!/bin/bash
########################################
#######   Merge From master To Development #######################
##################################################################
function resolveConfictRight(){

  filename=$1
  #### Primero leer la primera linea <<<<<<<<<<<
  salida1=$(sed '/./=' $filename | sed '/./N; s/\n/ /' | grep "<<<<" | awk '{print $1}')


  #### Leeer linea ======
  salida2=$(sed '/./=' $filename | sed '/./N; s/\n/ /' | grep "====" | awk '{print $1}')


  ### Borrar lo que hay entre <<<< y =====
  salida3=$(sed '/./=' $filename | sed '/./N; s/\n/ /' | grep ">>>>" | awk '{print $1}')

  salida4=$(echo -e "$salida1\n$salida2\n$salida3")
  numerosLinea=$(echo "$salida4" | sort -n)
  ### Eliminar linea >>>>>>>><
  #echo "Numeros de linea "
  #echo $numerosLinea
  pom=0;
  if [[ $file =~ pom\.xml$ ]]; then
    echo "      + Se chafara en development, el pom.xml y se pondrán los cambios de master."
    pom=1;
  else
    echo "      + Se mantendrán los cambios que había en development ignorando los que vienen de master."
  fi
  index=0;
  firstLine=0;
  secondLine=0;
  thirdLine=0;
  numBorradas=0;
  for line in $numerosLinea
    do
      index=$((index+1));
      #echo "line $index $line"
      if [[ $index -eq 3 ]]
      then
        thirdLine=$line
        index=0;
        if [[ $pom -eq 1 ]]
        then
          # Es un pom.xml
          lineasBorradas=$((numBorradas));
          firstLine=$((firstLine-lineasBorradas))
          secondLine=$((secondLine-lineasBorradas))
          dif=$((secondLine-firstLine+1))
          thirdLine=$((thirdLine-dif-lineasBorradas))
          #echo "Es un pom $filename"
          #echo "Cambios entre las lineas $firstLine $secondLine $thirdLine"
          sed -i "$firstLine,$secondLine""d" $filename
          sed -i "$thirdLine""d" $filename
          numBorradas=$((numBorradas+dif+1));
        else
          #No es un pom.xml
          #echo "No es un pom"
          lineasBorradas=$((numBorradas));
          firstLine=$((firstLine-lineasBorradas))
          secondLine=$((secondLine-lineasBorradas))
          thirdLine=$((thirdLine-lineasBorradas))
          dif=$((thirdLine-secondLine+1))
          #echo "Cambios entre las lineas $firstLine $secondLine $thirdLine"
          sed -i "$secondLine,$thirdLine""d" $filename
          sed -i "$firstLine""d" $filename
          numBorradas=$((numBorradas+dif+1));
        fi

      elif [[ $index -eq 2 ]]
      then
        secondLine=$line
      else
        firstLine=$line
      fi
    done
}
function avoidFilesExceptPom(){
  files=$(git diff --cached --name-only)
  if [ -z "$files" ]
    then
      echo "    ======================================================="
      echo "    5.1 No hay cambios"
      echo "    ======================================================="
      echo ""
  else
    echo "    ======================================================="
    echo "    5.1 Quitando ficheros excepto pom.xml del listado de cambios."
    echo "    ======================================================="
    echo ""
    for file in $files
      do
        if [[ $file =~ pom\.xml$ ]]; then
          echo ""
        else
          git reset HEAD $file
          echo "    - "$file
        fi
      done
  fi
  echo "    ======================================================="
  echo "    5.2 Realizando commit."
  echo "    ======================================================="
  echo ""
  git commit -m "Commit changes [skip ci]"
}
function checkIfThereIsConflicts(){
  files=$(git diff --name-only --diff-filter=U)
  if [ -z "$files" ]
    then
      echo "    ======================================================="
      echo "    7.2 No hay conflictos (Gracias también LUIS PELLICER)"
      echo "    ======================================================="
      echo ""
  else
    echo "    ======================================================="
    echo "    7.2 Resolviendo Conflictos en los siguientes ficheros. (Gracias LUIS PELLICER)"
    echo "    ======================================================="
    echo ""
    for file in $files
      do
        echo "    - "$file
        resolveConfictRight $file
        echo ""
        git add $file
      done
    echo "    Realizando commit del conflicto con mensaje resolved conflict. (Quitando ficheros java del index para que no se suban cambios)"

    git commit -m "Resolviendo conflicto [skip ci]"
    echo "";
    echo "    Realizando push del conflicto."
    git push --set-upstream origin development
  fi
}

function reintegration(){
  path=$1
  subpath=$(echo $1| sed 's/.*\///')
  rm -rf /tmp/reintegration
  mkdir /tmp/reintegration
  cd /tmp/reintegration;
  echo ""
  echo "  ==========================================================="
  echo "  1. Clonando en /tmp/reintegration"
  echo "  ==========================================================="
  echo ""
  git clone $path
  pwd
  cd $subpath
  echo ""
  echo "  ==========================================================="
  echo "  2. Realizando checkout master"
  echo "  ==========================================================="
  echo ""
  git checkout master
  echo ""
  echo "  ==========================================================="
  echo "  3. Realizando checkout development"
  echo "  ==========================================================="
  echo ""
  git checkout development
  echo ""
  echo "  ==========================================================="
  echo "  4. Mergeando Master en dev"
  echo "  ==========================================================="
  echo ""
  git merge --no-commit --no-ff master
  echo ""
  echo "  ==========================================================="
  echo "  5. Quitando cambios que no sean en pom.xml"
  echo "  ==========================================================="
  echo ""
  avoidFilesExceptPom;
  #Si no hay conflictos hacer el push
  echo ""
  echo "  ==========================================================="
  echo "  6. Realizando push"
  echo "  ==========================================================="
  echo ""
  git push --set-upstream origin development
  echo ""
  echo "  ==========================================================="
  echo "  7. Resolviendo Posibles conflictos"
  echo "  ==========================================================="
  echo ""
  checkIfThereIsConflicts;
}
p=$(echo $1 | sed 's/192.168.10.126/gitlab.mercury-tfs.com/g')
reintegration $p
