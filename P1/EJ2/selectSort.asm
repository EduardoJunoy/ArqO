.data
	array: .word 5, 3, 8, 4, 2, 9, 0, 7, 6, 1

.text
_start:
    la a1, array        # cargar la dirección base del array
    li a2, 10           # establecer el número de elementos en el array

insertion_sort:
    li a3, 1            # inicializar i = 1 (a3 será nuestro índice i)
i_loop:
    bge a3, a2, end_sort # si i >= tamaño_array, salir del bucle
    mv a4, a3            # j = i (a4 será nuestro índice j)

    # calcular la dirección de array[j] y cargar array[j] en a5
    slli t0, a4, 2       # t0 = j * 4
    add t0, a1, t0       # t0 = dirección base + (j * 4)
    lw a5, 0(t0)         # cargar array[j] en a5

j_loop:
    # si j <= 0, salir del bucle
    blez a4, end_j_loop
    # calcular la dirección de array[j-1] y cargar array[j-1] en a6
    addi t1, t0, -4      # t1 = dirección de array[j] - 4 (dirección de array[j-1])
    lw a6, 0(t1)         # cargar array[j-1] en a6

    # si array[j-1] <= array[j], salir del bucle
    ble a6, a5, end_j_loop

    # array[j] = array[j-1]
    sw a6, 0(t0)         # almacenar el valor de array[j-1] en array[j]

    # j = j - 1
    addi a4, a4, -1
    mv t0, t1            # actualizar la dirección de array[j]
    j j_loop

end_j_loop:
    # array[j] = key (key es el valor original de array[i] almacenado en a5)
    sw a5, 0(t0)

    # i = i + 1
    addi a3, a3, 1
    j i_loop

end_sort:
    # fin del programa
    li a7, 10            # código de salida
    ecall               # llamar al sistema para terminar