#!/bin/bash

fDAT=3_speedup.dat
fPNG=3_speedup.png

# Borrar los archivos anteriores
rm -f $fPNG
rm -f $fDAT

touch $fDAT
touch $fPNG

cores=3
P=1

# Calcular los valores de start y end
start=$((512 + P))
end=$((1600 + 512 + P))

# Recorrer los tamaños
for ((size = start; size <= end; size += 64)); do
    echo "Ejecutando con tamaño ${size}"

    accel_medio=0.0
    for k in $(seq 1 5); do
        aux_par=$(./mult_1 ${size} ${cores} | grep -oE '[0-9]+\.[0-9]+')
        aux_seq=$(./mult_seq ${size} ${cores} | grep -oE '[0-9]+\.[0-9]+')

        # Calcular la aceleración
        accel=$(echo "$aux_seq / $aux_par" | bc -l)
        accel_medio=$(echo "$accel_medio + $accel" | bc -l)
    done

    accel_medio=$(echo "$accel_medio / 5" | bc -l)
    # Cada tamaño con su aceleración correspondiente
    echo "${size} ${accel_medio}" >> $fDAT
done

# Graficar
gnuplot << END_GNUPLOT
set title "Acceleration"
set ylabel "Acceleration"
set xlabel "Size"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "Acceleration"
replot 
quit
END_GNUPLOT
