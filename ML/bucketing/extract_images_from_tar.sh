#!/bin/sh

FILES="
desert-n13121104.txt
Aquatic-n13121544.txt
bulbous-n13134302.txt
Herb-n12205694.txt
houseplant-n13083023.txt
poisonous-n13100156.txt
Pteridophyte-n11545524.txt
Spermadophyte-n11552386.txt
succulent-n13084184.txt
vine-n13100677.txt
Weed-n13085113.txt
woodyplant-n13103136.txt
"
for list in $FILES
do
        for f in $(cat "$list" | sed 's/\r$//')
        do
		if tar -xf fall11_whole.tar "$f.tar"; then
		mkdir "$f"
		mv "$f.tar" "$f/"
		cd "$f"
		tar -xf "$f.tar"
		rm -f "$f.tar"
		cd ..
                else
                echo $f >> error.txt
                fi
        done
done
 
