#!/usr/bin/env bash

containsSubstring(){

  if [[ $1 == *"$2"* ]];
  then
    echo "True"
  else
    echo "False"
  fi
}

isEqualIgnoreCase(){
  #deleting dot(.) from names
  local var1=`echo $1 | tr -d '[. ]'`
  local var2=`echo $2 | tr -d '[. ]'`
  shopt -s nocasematch
  if [[ $(echo $1 | tr -d '[:space:]') = $(echo $2 | tr -d '[:space:]') ]]; then
    echo "True"
  else
    echo "False"
  fi
  shopt -u nocasematch
}

makeAbsentsList(){
  for f in  `cat CSE_322.csv`
  do
    flag=0
    roll=$(echo $f | cut -f 1 -d, | sed 's/[^0-9]//g')
    nameFromCSV=$(echo $f | cut -f 2 -d, )

    for f2 in $(ls *[0-9].zip)
    do
      if [[ $(containsSubstring "$f2" "$roll") == "True"  ]]; then
        nameFromFile=$(echo $f2 | cut -d_ -f1 )

        flag=1
        break
      fi
    done

    if [[ flag -eq 0 ]]; then
      echo $roll >> Output/Absents
      echo "$roll 0">> Output/Marks
    fi

  done
}
#called from temp directory
rollInAbesntList(){
  flag=0
  for r in `cat ../Output/Absents`
  do
    entity=$(echo $r | sed 's/[^0-9]//g' )
    if [[ $entity = $1 ]]; then
      flag=1
      echo "True"
      break
    fi
  done
  if [[ flag -eq 0 ]]; then
    echo "False"
  fi
}
deleteFromAbsents(){
  sed -i '/"$1"/d' ../Output/Absents
}

rollAgainstName(){
  flag=0;
  ret=''
  cnt=0
  for f in  `cat ../CSE_322.csv`
  do
    roll=$(echo $f | cut -f 1 -d, | sed 's/[^0-9]//g')
    nameFromCSV=$(echo $f | cut -f 2 -d, )

    if [[ $(isEqualIgnoreCase $1 $nameFromCSV) = "True" ]]; then
      if [[ $(rollInAbesntList $roll ) = "True" ]]; then
        cnt=$(( cnt + 1))
        ret=$roll
      fi
    fi
  done

  if (( cnt > 1 )); then
    echo "False"
  else
    echo $ret
  fi
}

rm -rf temp
rm -rf Output
mkdir temp
mkdir Output
mkdir Output/Extra
unzip SubmissionsAll.zip > /dev/null

IFS=$'\n'

makeAbsentsList

for f in $(ls *[0-9].zip)
do
  #echo $f
  unzip $f -d temp > /dev/null

  cd temp
  how=$(ls -1 | wc -l)
  if [[ $how -eq 1 ]]; then
    onlyRoll=$(ls | grep -E '^[0-9]+$' | wc -l)
    rollWithTxt=$(ls -1 | grep  "[0-9]\{7\}" | wc -l)

    if [[ $onlyRoll -eq 1 ]]; then
      fileName=$(ls | grep -E '[0-9]+')
      echo "$fileName 10" >> ../Output/Marks
      mv $fileName "../Output/"
    elif [[ $rollWithTxt -eq 1 ]]; then
      fileName=$(ls -1 | grep  "[0-9]\{7\}")
      toReplace=$(echo $fileName | grep -o "[0-9]\{7\}")
      mv $fileName $toReplace
      echo "$toReplace 5" >> ../Output/Marks
      mv $toReplace ../Output/
    else
        fileName=$(ls)
        roll=$(echo $f | cut -f5 -d_ | cut -f1 -d. |  sed 's/[^0-9]//g' )

        if [[ $roll =~ [0-9]{7} ]]; then
          mv "$fileName" "$roll"
          mv $roll ../Output
          echo "$roll 0">> ../Output/Marks
        else
          nameFromFile=$(echo $f | cut -d_ -f1 )
          rollFromRoster=$(rollAgainstName $nameFromFile)
          if [[ $rollFromRoster = "False" ]]; then
            mkdir $nameFromFile
            mv $fileName "$nameFromFile"
            mv $nameFromFile ../Output/Extra
          else
            mv "$fileName" "$rollFromRoster"
            mv $rollFromRoster ../Output
            deleteFromAbsents $rollFromRoster
            echo "$rollFromRoster 0">> ../Output/Marks

          fi

        fi

    fi
    #multiple
  else
    fileName=$(ls)
    roll=$(echo $f | cut -f5 -d_ | cut -f1 -d.  |  sed 's/[^0-9]//g' )
    if [[ $roll =~ [0-9]{7} ]]; then
      mkdir $roll
      mv $fileName "$roll"
      mv $roll ../Output
      echo "$roll 0">> ../Output/Marks
    else
      nameFromFile=$(echo $f | cut -d_ -f1 )
      rollFromRoster=$(rollAgainstName $nameFromFile)

      if [[ $rollFromRoster = "False" ]]; then
        mkdir $nameFromFile
        mv $fileName "$nameFromFile"
        mv "$nameFromFile" ../Output/Extra
      else
        mkdir $rollFromRoster
        mv $fileName "$rollFromRoster"
        mv $rollFromRoster ../Output
        deleteFromAbsents $rollFromRoster
        echo "$rollFromRoster 0">> ../Output/Marks
      fi
    fi

  fi
  cd ..
done

rm -rf temp
sort -o Output/Marks Output/Marks >> /dev/null
sort -o Output/Absents  Output/Absents   >> /dev/null
find . \( -name '*[0-9].zip' -o -name '*[0-9].rar' \) -exec rm -f {} +
