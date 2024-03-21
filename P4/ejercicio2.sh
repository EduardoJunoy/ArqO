#!/bin/bash

fRES=2_aux.dat
fDAT1=2_time.dat
fDAT2=2_speedup.dat
fPNG1=2_time.png
fPNG2=2_speedup.png


# borrar los ficheros y pngs anteriores
rm -f $fPNG1
rm -f $fPNG2
rm -f $fRES
rm -f $fDAT1
rm -f $fDAT2
touch $fRES
touch $fDAT2
touch $fDAT1
touch $fPNG1
touch $fPNG2

echo "EJERCICIO 2" >> $fRES
echo "Resultado de usar critical" >> $fRES
./pescalar_par1 >> $fRES
echo "Resultado de usar atomic" >> $fRES
./pescalar_par2 >> $fRES
echo "Resultado de usar reduction" >> $fRES
./pescalar_par3 >> $fRES

# EJERCICIO 2.5

#size[0]=10000
#size[1]=50000
#size[2]=100000
#size[3]=300000
#size[4]=500000

# size[0]=15000000
# size[1]=50000000
# size[2]=100000000
# size[3]=200000000
# size[4]=400000000

data=(0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)
old=(0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)
su=(0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)
var=5

echo "PRUEBAS" >> $fRES

#recorremos los tamaños
for ((j = 75000; j <= 150000; j += 1000)); do

    echo "Ejecutando size: ${j}"
    t_medio_seq=0.0
    for k in $(seq 0 9); do
        aux=$(./pescalar_serie ${j} | grep "Tiempo" | awk '{print $2}')
        t_medio_seq=$(echo "$t_medio_seq + $aux" | bc -l)
    done

    t_medio_par=0.0
    for k in $(seq 0 9); do
        aux=$(./pescalar_par3 ${j} | grep "Tiempo" | awk '{print $2}')
        t_medio_par=$(echo "$t_medio_par + $aux" | bc -l)
    done

    # cada tamaño con su tiempo correspondiente
    echo "${j} ${t_medio_seq} ${t_medio_par}" >> $fDAT1

    echo "$t_medio_seq / $t_medio_par"
    t_diff=$(echo "$t_medio_par / $t_medio_seq" | bc -l)
    echo "${j} ${t_diff}" >> $fDAT2
    
done

#grafica de lectura
gnuplot << END_GNUPLOT
set title "Execution Time"
set ylabel "Execution time (s)"
set xlabel "Vector Size"
set key right bottom
set grid
set term png
set output "2_time.png"
plot "2_time.dat" using 1:2 with lines lw 2 title "sequencial", \
     "2_time.dat" using 1:3 with lines lw 2 title "paralell"
replot
quit
END_GNUPLOT

#grafica de lectura
gnuplot << END_GNUPLOT
set title "Speed up"
set ylabel "Speed up"
set xlabel "Vector Size"
set key right bottom
set grid
set term png
set output "2_speedup.png"
plot "2_speedup.dat" using 1:2 with lines lw 2 title ""
replot
quit
END_GNUPLOT
