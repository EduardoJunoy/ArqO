# EJECUCIÓN Y CREACIÓN DE GRÁFICAS DEL EJERCICIO 2
# AUTORES: PABLO ANTÓN ALAMILLO Y EDUARDO JUNOY ORTEGA

#!/bin/bash

# DATOS PARA PRUEBAS DE CACHÉ
cache_size=(1024 2048 4096 8192)
N_init=1024 
N_incr=1024
N_final=5120
f_slow=slow_out.dat
f_fast=fast_out.dat

echo "Ejecutando pruebas de cache..."

# EJECUCIÓN DE LAS PRUEBAS DE CACHÉ
for Cache in "${cache_size[@]}"; do
    fDAT=cache_$Cache.dat
    rm -f $fDAT 
    touch $fDAT

    for ((N = N_init ; N <= N_final ; N += N_incr)); do
        valgrind --tool=cachegrind --cachegrind-out-file=$f_slow --I1=$Cache,1,64 --D1=$Cache,1,64 --LL=8388608,1,64 ./slow $N
        valgrind --tool=cachegrind --cachegrind-out-file=$f_fast --I1=$Cache,1,64 --D1=$Cache,1,64 --LL=8388608,1,64 ./fast $N

        # Extraer los datos de fallos de caché
        D1mrSlow=$(cg_annotate $f_slow | head -n 18 | tail -n 1 | awk '{print $9}')
        D1mrFast=$(cg_annotate $f_fast | head -n 18 | tail -n 1 | awk '{print $9}')
        D1mwSlow=$(cg_annotate $f_slow | head -n 18 | tail -n 1 | awk '{print $15}') 
        D1mwFast=$(cg_annotate $f_fast | head -n 18 | tail -n 1 | awk '{print $15}')

        val="$N    $D1mrSlow    $D1mwSlow    $D1mrFast    $D1mwFast"
        val=${val//[,]/}
        echo $val
        echo "$val" >> $fDAT 
    done
done

# BORRAR FICHEROS AUXILIARES
rm -f $f_slow $f_fast

# DATOS PARA PRUEBAS DE TIEMPO
Ninicio=1024
Npaso=1024
Nfinal=16384
fDAT_time=slow_fast_time.dat
fPNG_time=slow_fast_time.png

rm -f $fDAT_time $fPNG_time
touch $fDAT_time

echo "Running slow and fast time tests..."

# EJECUCIÓN DE LAS PRUEBAS DE TIEMPO
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
    echo "N: $N / $Nfinal..."
    slowTime=$(./slow $N | grep 'time' | awk '{print $3}')
    fastTime=$(./fast $N | grep 'time' | awk '{print $3}')
    echo "$N    $slowTime    $fastTime" >> $fDAT_time
done

# GENERACIÓN DE GRÁFICAS CON GNUPLOT

echo "Generando gráficas de fallos de cache..."

# CONFIGURACIÓN DE LOS ARCHIVOS DE DATOS
data_files=("cache_1024.dat" "cache_2048.dat" "cache_4096.dat" "cache_8192.dat")

# CONFIGURACIÓN DE LAS GRÁFICAS
output_read="cache_lectura.png"
output_write="cache_escritura.png"

# COMANDOS PARA GENERAR GRÁFICAS CON GNUPLOT
gnu_commands_read="set title 'Fallos de lectura de datos'; set xlabel 'Tamaño de la matriz (N)'; set ylabel 'Número de fallos'; set terminal png; set output '$output_read'; plot "
gnu_commands_write="set title 'Fallos de escritura de datos'; set xlabel 'Tamaño de la matriz (N)'; set ylabel 'Número de fallos'; set terminal png; set output '$output_write'; plot "

for file in "${data_files[@]}"; do
    cache=$(echo "$file" | cut -d '_' -f 2 | cut -d '.' -f 1)
    gnu_commands_read+="'$file' using 1:2 with linespoints title 'Cache $cache', "
    gnu_commands_write+="'$file' using 1:4 with linespoints title 'Cache $cache', "
done

# QUITAR LA ÚLTIMA COMA
gnu_commands_read=${gnu_commands_read%, }
gnu_commands_write=${gnu_commands_write%, }

# EJECUTAR GNUPLOT PARA GENERAR LAS GRÁFICAS
echo "$gnu_commands_read" | gnuplot
echo "$gnu_commands_write" | gnuplot

# Gráficas de Fallos de Caché en Función del Tamaño de la Matriz (N)
gnuplot <<EOF
set title 'Fallos de caché en función de N para diferentes tamaños de caché'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Número de fallos de caché'
set terminal png
set output 'cache_vs_N.png'
plot 'cache_1024.dat' using 1:2 with linespoints title 'Cache 1024', \
     'cache_2048.dat' using 1:2 with linespoints title 'Cache 2048', \
     'cache_4096.dat' using 1:2 with linespoints title 'Cache 4096', \
     'cache_8192.dat' using 1:2 with linespoints title 'Cache 8192'
EOF

# Comparación de Programa "Slow" y Programa "Fast" en un Tamaño de Caché Fijo
gnuplot <<EOF
set title 'Comparación de "Slow" y "Fast" en Cache 1024'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Número de fallos de caché'
set terminal png
set output 'slow_vs_fast1.png'
plot 'cache_1024.dat' using 1:2 with linespoints title 'Slow', \
     'cache_1024.dat' using 1:4 with linespoints title 'Fast'
EOF

# Comparación de Programa "Slow" y Programa "Fast" en un Tamaño de Caché Fijo
gnuplot <<EOF
set title 'Comparación de "Slow" y "Fast" en Cache 2048'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Número de fallos de caché'
set terminal png
set output 'slow_vs_fast2.png'
plot 'cache_2048.dat' using 1:2 with linespoints title 'Slow', \
     'cache_2048.dat' using 1:4 with linespoints title 'Fast'
EOF


# Comparación de Programa "Slow" y Programa "Fast" en un Tamaño de Caché Fijo
gnuplot <<EOF
set title 'Comparación de "Slow" y "Fast" en Cache 4096'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Número de fallos de caché'
set terminal png
set output 'slow_vs_fast3.png'
plot 'cache_4096.dat' using 1:2 with linespoints title 'Slow', \
     'cache_4096.dat' using 1:4 with linespoints title 'Fast'
EOF


# Comparación de Programa "Slow" y Programa "Fast" en un Tamaño de Caché Fijo
gnuplot <<EOF
set title 'Comparación de "Slow" y "Fast" en Cache 8192'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Número de fallos de caché'
set terminal png
set output 'slow_vs_fast4.png'
plot 'cache_8192.dat' using 1:2 with linespoints title 'Slow', \
     'cache_8192.dat' using 1:4 with linespoints title 'Fast'
EOF

# Gráfica de Tiempo de Ejecución para "Slow" y "Fast"
gnuplot <<EOF
set title 'Tiempo de ejecución en función de N para "Slow" y "Fast"'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Tiempo de ejecución (segundos)'
set terminal png
set output 'time_vs_N.png'
plot 'slow_fast_time.dat' using 1:2 with linespoints title 'Slow', \
     'slow_fast_time.dat' using 1:3 with linespoints title 'Fast'
EOF

echo "Gráficas generadas."