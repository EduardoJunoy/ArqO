#include "arqo4.h"

#include <omp.h>
#include <stdio.h>

float **multiply(float **matrix1, float **matrix2, float **m2_trans, int n);
void transpuesta(float **matrix, float **res, int n);

int main(int argc, char *argv[])
{
    int n, n_threads;
    struct timeval fin, ini;

    printf("Word size: %ld bits\n", 8 * sizeof(float));

    if (argc != 3)
    {
        printf("Error: ./%s <matrix size>\n", argv[0]);
        return -1;
    }
    n = atoi(argv[1]);
    n_threads = atoi(argv[2]);
    omp_set_num_threads(n_threads);

    float **matrix1 = generateMatrix(n);
    float **matrix2 = generateMatrix(n);
    float **m2_trans = generateEmptyMatrix(n);
    if (!matrix1 || !matrix2 || !m2_trans)
    {
        return -1;
    }

    gettimeofday(&ini, NULL);
    float **res = multiply(matrix1, matrix2, m2_trans, n);
    if (!res)
    {
        return -1;
    }

    gettimeofday(&fin, NULL);
    printf("Execution time: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) - (ini.tv_sec * 1000000 + ini.tv_usec)) * 1.0 / 1000000.0);

    /*
    for(int i = 0; i<n; i++){
        for(int j = 0; j<n; j++){
            printf("%lf ", res[i][j]);
        }
        printf("\n");
    }
    */

    freeMatrix(matrix1);
    freeMatrix(matrix2);
    freeMatrix(m2_trans);
    freeMatrix(res);
    return 0;
}

float **multiply(float **matrix1, float **matrix2, float **m2_trans, int n)
{
    float **res = generateEmptyMatrix(n);
    if (!res)
    {
        return NULL;
    }
    int i, j, k;

    transpuesta(matrix2, m2_trans, n);

#pragma omp parallel for shared(matrix1, m2_trans, res, n) private(j, k)
    for (i = 0; i < n; i++)
    {
        for (j = 0; j < n; j++)
        {
            for (k = 0; k < n; k++)
            {
                res[i][j] += matrix1[i][k] * m2_trans[j][k];
            }
        }
    }

    return res;
}

void transpuesta(float **matrix, float **res, int n)
{
    int i, j;
    for (i = 0; i < n; i++)
    {
        for (j = 0; j < n; j++)
        {
            res[j][i] = matrix[i][j];
        }
    }
}