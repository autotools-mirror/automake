
testfile()
{
	filename=$1
	echo $filename
	perl -I. parser.pl $filename > $filename.gv
	unflatten -f -l 10 -c 10 -o $filename1.gv $filename.gv
	dot -Tpng $filename1.gv > $filename.png
	rm $filename.gv $filename1.gv
}

if [ $# -eq 0 ]
then
	for entry in t/*.txt
	do
		testfile $entry
	done
else
	for entry in $@
	do
		testfile $entry
	done
fi
