//#include <openssl/sha.h>
//#include <stdint.h>

/*void sha256(const double* data, int length, uint8_t* output) {
    SHA256_CTX *sha256;
    sha256 = SHA256_CTX_new();
    SHA256_Init(sha256);
    for (int i = 0; i < length; i++) {
        SHA256_Update(sha256, &data[i], sizeof(double));
    }
    SHA256_Final(output, sha256);
    SHA256_CTX_free(sha256);
}
*/

#include <stdlib.h>
typedef unsigned int uint32_t;

// Предположим, что возвращаемый хэш имеет фиксированный размер
#define HASH_SIZE 8

// Определение функции
void sha256(double* data, int length, uint32_t* hash) {
    // Реализация алгоритма хэширования SHA-256
    // Здесь происходит вычисление хэш-значения на основе данных, переданных в функцию
    // Для примера присвоим значения элементам хэша
    for (int i = 0; i < HASH_SIZE; i++) {
        // вычисление чего-то
    }
}