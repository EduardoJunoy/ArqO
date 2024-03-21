#!/bin/bash

fDAT=3_time.dat
fPNG=3_time.png

# borrar los ficheros y pngs anteriores
rm -f $fPNG
rm -f $fDAT

touch $fDAT
touch $fPNG

size=1000

# recorremos los tamaños
for i in $(seq 1 4); do
    echo "Ejecutando con ${i} nucleos"

    t_medio_seq=0.0
    t_medio_1=0.0
    t_medio_2=0.0
    t_medio_3=0.0

    for k in $(seq 1 5); do
        echo "seq"
        aux=$(./mult_seq ${size} ${i} | grep -oE '[0-9]+\.[0-9]+')
        t_medio_seq=$(echo "$t_medio_seq + $aux" | bc -l)

        echo "1"
        aux=$(./mult_1 ${size} ${i} | grep -oE '[0-9]+\.[0-9]+')
        t_medio_1=$(echo "$t_medio_1 + $aux" | bc -l)

        echo "2"
        aux=$(./mult_2 ${size} ${i} |  grep -oE '[0-9]+\.[0-9]+')
        t_medio_2=$(echo "$t_medio_2 + $aux" | bc -l)

        echo "3"
        aux=$(./mult_3 ${size} ${i} | grep -oE '[0-9]+\.[0-9]+')
        t_medio_3=$(echo "$t_medio_3 + $aux" | bc -l)
    done

    t_medio_seq=$(echo "$t_medio_seq / 5" | bc -l)
    t_medio_1=$(echo "$t_medio_1 / 5" | bc -l)
    t_medio_2=$(echo "$t_medio_2 / 5" | bc -l)
    t_medio_3=$(echo "$t_medio_3 / 5" | bc -l)

    # cada tamaño con su tiempo correspondiente
    echo "${i} ${t_medio_seq} ${t_medio_1} ${t_medio_2} ${t_medio_3}" >> $fDAT
done

#grafica de lectura
gnuplot << END_GNUPLOT
set title "Execution Time"
set ylabel "Execution time (s)"
set xlabel "Number of Cores"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "Sequential", \
     "$fDAT" using 1:3 with lines lw 2 title "1 Loop", \
     "$fDAT" using 1:4 with lines lw 2 title "2 Loop", \
     "$fDAT" using 1:5 with lines lw 2 title "3 Loop"
replot 
quit
END_GNUPLOT
