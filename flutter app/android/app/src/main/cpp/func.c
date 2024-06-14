#include <stdlib.h>
#include <stdint.h>
#include <android/log.h>


void sha256(double* data, int length, uint8_t* hash) {
    for (int i = 0; i < length-1; i++) {
        double absoluteValue = fabs(data[i]); // Получаем абсолютное значение числа
        double fractionalPart = fmod(absoluteValue, 1.0);
        uint8_t byte = (uint8_t)(fractionalPart * UINT8_MAX); // Преобразуем дробную часть в байт
        hash[i] ^= byte; // Выполняем операцию XOR между байтом хэша и байтом дробной части числа
        __android_log_print(ANDROID_LOG_INFO, "YourTag", "Value_%d: %d\tOrigin value:%f", i, byte, fractionalPart);
    }
}