# cut out just the generated portion (simple enough, no need to modify python part)
cat ../gate.c | head -n 190 | tail -n 183 > cnw.c

defs=

rm log.txt -f;

for vr in $(awk -F' ' '{ print $2 }' cnw.c); do

 printf -- "\n--> $vr <--\n" >> log.txt

 # find all variables that only get used once
 grep -n -E "[ (]~?$vr[ ;)]" cnw.c > tmp.grep;
 if [ $(wc -l tmp.grep | sed "s/ [^ ]*$//") -eq 2 ]; then

echo "tmp.grep: $(cat tmp.grep)" >> log.txt

  # find the definition of the variable
  def=$(sed -n "1s/:.*\$//p" tmp.grep)

  defs="$defs\n${def}d"

echo "def=$def" >> log.txt

  # find the only use of the variable
  use=$(sed -n "2s/:.*\$//p" tmp.grep)

echo "use=$use" >> log.txt

  # find just the definition's rvalue
  def2=$(sed -n "${def}p" cnw.c | sed -E "s/ *cell [^ ]+ = //" | sed -E "s/;//" | sed "s/&/\\\&/g")

echo "def2=$def2" >> log.txt

  # replace the single occurence with def2
  sed -i -E "${use}s/([ (]~?)$vr([ ;)])/\1($def2)\2/" cnw.c

 fi

 rm tmp.grep

done

sed -i "$(echo -e $defs)" cnw.c

# combine together, because I don't know how to use the template
cat top.c cnw.c bottom.c > gate-compact.c

CC="${CC:-gcc}"

# compile using gcc or your compiler
$CC gate-compact.c -o gate-compact
