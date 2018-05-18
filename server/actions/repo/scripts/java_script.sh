#!/bin/bash
# Script for grading Java programs (CSE 8B/11)
#
# Author:   Kenneth Truong
# Version:  2.0
# Date:     06/19/16
# Usage: ./java_script.sh <Optional Bonus Due Date>
# Example: ./java_script.sh "01/24/2015 15:00"
# Must have PA#.prt and input.txt within same folder

red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;34m"
clear="\033[0m"

#Enable bash's nullglob setting so that pattern *.P1 will expand to empty string if no such files
shopt -s nullglob

echo "Beginning of java_script.sh"

#Check if bonus date specified
if [[ -n $1 ]]; then
  # Bonus date change 15:00 if different time
  bonus=$(date +'%s' -d "${1}")
  echo "Set bonus date to $1"
else
  # NO bonus dates so just setting artbitrary date in past
  bonus=$(date +'%s' -d "01/24/1991 15:00:00.000")
  echo "Set to default bonus date"
fi

IsPA7=""
input_file=""
if [ -e "PA7.prt" ]; then
    echo "Setting IsPA7 to true"
    IsPA7="true"
    input_file="../pa7_in"
elif [ ! -e "input.txt" ]; then
  echo -en "Error: Missing file: \"input.txt\""
  exit -1
else
    echo "Setting IsPA7 to false"
    IsPA7="false"
fi

echo | pwd
prt=(*.prt)
if test ${#prt[@]} -ne 1; then
  echo -en "Error: Missing PA prt file: \"PA#.prt\""
  exit -1
else
  #Parse PA#.prt for output (We are looking for a line that starts with output)
  echo "Parse $prt for output and write out to output.txt"
  awk -v regex=".*output" '$0 ~ regex {seen = 1}
     seen {print}' $prt > output.txt
fi

# This file helps keeps store all the students that turned in their assignment early for bonus
if [ -e bonusList ]; then
  rm bonusList
fi
# Variable to keep track of bonus list
bonuslist=""

if [ "$IsPA7" == "false" ]; then
    echo -en "Not PA7"

    echo | pwd
    repos=(*/)
    #Outermost loop, go through each tutor's directories and grade assignments
    for dir in ${repos[@]}; do
      echo "Copying input.txt, output.txt, and $prt into $dir and cd-ing into it"
      cp input.txt output.txt $prt $dir
      cd $dir

      assignments=(*.P*)
      # Get filenames
      if test ${#assignments[@]} -le 0; then
        echo "There are 0 assignments"
        continue
      fi

      echo "counter and readPRT set to 0 and false respectively"
      counter=0
      readPRT=false # Flag to help determine if student is missing in PRT file

      # Loop until all assignments are compiled and ran
      while [ $counter -lt ${#assignments[@]} ]; do
        echo "counter = $counter"
        #Parse PA.prt file
        while read LINE
        do
          [ -z "$LINE" ] && continue
          #Find PA's info in PA.prt file for bonus date
          if [[ "$LINE" =~ "${assignments[${counter}]%.*}" ]] || $readPRT
          then
            fname="${assignments[${counter}]%.*}"
            echo "fname = $fname"

            # This student was missing from PA.prt so we can't give them bonus
            if ! $readPRT ; then
              # Convert bonus date of PA to seconds
              # Get date Each line in PA.prt has the turn in date on the 6th 7th 8th column
              filetime=$(date --date="$(echo $LINE | cut -d' ' -f6,7,8)" +%s)

              # Check for extra credit
              if [ $filetime -le $bonus ]; then
                bonuslist="${bonuslist}${fname}\n"
              fi
            fi
            readPRT=false

            #Untar and compile java file
            tar -xvf ${assignments[${counter}]} > /dev/null

            #TODO!! Correct the file
            # Spits out the first .java file in the current directory
            javaFile=$(ls *.java | head -n 1)
            # Extracts only the filename without .java?
            javaFile="${javaFile%.java}"

            # Getting student's code to display on PAGrader UI
            sed 's/\r$//' *.java > ${assignments[${counter}]%.*}.txt

            #Compile
            javac *.java &> $fname.out.html
            #Check if error
            if [ $? -ne 1 ]; then
              #Run program manually feeding input and printing out output in background process
              if [ -e input ]; then
                rm input
              fi

              # temp used to feed input for a PARTICULAR assignment?
              cp input.txt temp

              # number of lines in input.txt
              inCount=$(wc -l < input.txt)
              test `tail -c 1 "input.txt"` && ((inCount++))
              count=0
              # Run until all input given
              while [ $count -lt $inCount ]
              do
                if [ -e input ]; then
                  if [[ $errorCode -eq 121 ]]; then
                    # For some reason the script is terminating programs when it should keep going
                    echo "<p class='alert alert-danger'>Program terminated by grading script remote I/O error.\nPlease run their program manually or check their code.</p>" >> $fname.out.html
                  else
                    echo "<p class='alert alert-danger'>Program ended on last input... Restarting program...</p>" >> $fname.out.html
                  fi
                fi

                if [ -e "strace.fifo" ]; then
                  rm strace.fifo
                fi

                # This is the core of the script
                # This uses strace to help feed input
                # stdbuf -o0 helps flush input along with the output
                # perl -e "alarm 2; exec @ARGV" "./a.out" helps kills the process if it takes over 2 seconds
                inputFlag=false
                mkfifo strace.fifo
                {
                  while read -d, trace; do
                    if [[ $trace = *"read(0" ]] ; then
                      IFS= read -rn1 answer <&3 || break
                      answer=${answer:-$'\n'}
                      printf "<font style='color: purple;'>$answer</font>" >> $fname.out.html
                      # input is updated along the way, compared with the Susan-Provided input.txt
                      printf "$answer" >> input
                      diff -w -B input input.txt > /dev/null
                      if [[ $? -eq 0 ]] ; then
                        # End of input
                        inputFlag=true
                      fi
                      # To the console to actually continue running student's program; previous printf just include to various files, doesn't actually run program
                      printf %s "$answer"
                    elif $inputFlag ; then
                      killall -15 a.out > /dev/null 2>&1
                    fi
                  done < strace.fifo 3< temp | strace -o strace.fifo -f -e read stdbuf -o0 perl -e "alarm 8; exec @ARGV" "java ${javaFile}"
                } >> $fname.out.html 2>>error

                errorCode=$?
                #Check if the program was terminated
                if [[ $errorCode -eq 142 ]] ; then
                  printf "<p class='alert alert-danger'>Program terminated because of infinite loop.\nPlease run their program manually or check their code.</p>" > $fname.out.html
                  rm error # Error is from infinite loop
                  break
                elif [[ $errorCode -eq 143 ]] ; then
                  printf "<p class='alert alert-danger'>Program terminated because it was waiting for more input than expected.\n(Note: This could mean they have getchar() at the end of their code.\nPlease run their program manually or check their code.)</p>" >> $fname.out.html
                  rm error # Error is from running out of input
                  break
                elif [ -s error ] ; then
                  echo "<h2 class='alert alert-danger'>Runtime Error!</h2>" >> $fname.out.html
                  #Only one that utilizes error; takes out the error output from runtime to html to display on PAGrader
                  cat error >> $fname.out.html
                  rm error # Run time error
                  break
                fi

                # Remove empty error files
                if [ -e error ] ; then
                  rm error
                fi

                diff -w -B input input.txt > /dev/null
                if [ $? -eq 1 ] ; then
                   test 'tail -c 1 "input"' && echo "" >> input
                   count=$(wc -l < input)
                   test `tail -c 1 "input"` && ((count++))
                   tail -n $(expr ${count} - ${inCount}) input.txt > temp
                else
                   rm strace.fifo
                   break
                fi
              done

              if [ -e input ] ; then
                rm input
              fi

              rm temp *.java *.class
            else  #Error while compiling
              echo "<h2 class='alert alert-danger'>Compile Error!</h2>" | cat - $fname.out.html > temp && mv temp $fname.out.html
            fi
            counter=$((counter+1))
            echo "The incremented counter is $counter"
            [ $counter -eq ${#assignments[@]} ] && break
          fi
        done < $prt
        readPRT=true
      done

      if [ -e "strace.fifo" ]; then
        rm strace.fifo
      fi

      rm input.txt $prt
      cd ..
    done
fi

#TODO
if [ "$IsPA7" == "true" ]; then #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    repos=(*/)
    # Outermost loop, go through each tutor's directories, eg. cs11u1_PA7
    for dir in ${repos[@]}; do
      # Currently in /PA7, copying various finals into a specific tutor's directory, eg cs11u1_PA7
      cp input.txt output.txt $prt $dir
      cd $dir

      assignments=(*.P*)
      # Get filenames
      if test ${#assignments[@]} -le 0; then
        continue
      else
        echo $dir
      fi

      counter=0
      readPRT=false # Flag to help determine if student is missing in PRT file

      # Loop until all assignments are compiled and ran
      while [ $counter -lt ${#assignments[@]} ]; do
        #Parse PA.prt file
        while read LINE
        do
          [ -z "$LINE" ] && continue
          #Find PA's info in PA.prt file for bonus date
          if [[ "$LINE" =~ "${assignments[${counter}]%.*}" ]] || $readPRT
          then
            fname="${assignments[${counter}]%.*}"

            # This student was missing from PA.prt so we can't give them bonus
            if ! $readPRT ; then
              # Convert bonus date of PA to seconds
              # Get date Each line in PA.prt has the turn in date on the 6th 7th 8th column
              filetime=$(date --date="$(echo $LINE | cut -d' ' -f6,7,8)" +%s)

              # Check for extra credit
              if [ $filetime -le $bonus ]; then
                bonuslist="${bonuslist}${fname}\n"
              fi
            fi
            readPRT=false

            #Untar and compile java file
            tar -xvf ${assignments[${counter}]} > /dev/null

            #TODO!! Correct the file
            javaFile=$(ls *.java | head -n 1)
            javaFile="${javaFile%.java}"

            # Removes special characters from Windows to be able to display on PAGrader UI
            sed 's/\r$//' *.java > ${assignments[${counter}]%.*}.txt

            #Compile
            javac *.java &> $fname.out.html
            #Check if compile error
            if [ $? -ne 1 ]; then
              # Kills process if it is over 8 seconds, input_file is path to the pa7_in
              # &>> $fname.out.html because the students handle error checking & write to STDERR
              # So we just send all the output to their fname.out.html
              perl -e "alarm 8; exec @ARGV" "java ${javaFile} ${input_file}" &>> $fname.out.html

              errorCode=$?
              #Check if the program was terminated
              if [[ $errorCode -eq 142 ]] ; then
                # Error is from infinite loop
                printf "<p class='alert alert-danger'>Program terminated because of infinite loop.\nPlease run their program manually or check their code.</p>" > $fname.out.html
              elif [[ $errorCode -eq 143 ]] ; then
                # Error is from running out of input
                printf "<p class='alert alert-danger'>Program terminated because it was waiting for more input than expected.\n(Note: This could mean they have getchar() at the end of their code.\nPlease run their program manually or check their code.)</p>" >> $fname.out.html
              # Removed error file for Runtime because students write to STDERR in PA, no way to determine actual error & their intended error
              fi

              rm temp *.java *.class
            else  #Error while compiling
              echo "<h2 class='alert alert-danger'>Compile Error!</h2>" | cat - $fname.out.html > temp && mv temp $fname.out.html
            fi
            # Increment counter to move on to the next assignment in the tutor's directory
            counter=$((counter+1))
            [ $counter -eq ${#assignments[@]} ] && break
          fi
        done < $prt
        readPRT=true
      done

      rm input.txt $prt
      cd ..
    done
fi

printf "${bonuslist}" >> bonusList
