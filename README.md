# # BasicInterpreter 
Этот проект реализует часть интерпретатора языка **LOLCODE** с использованием **Bison** и **Flex**. Основная цель проекта — продемонстрировать построение парсера и сканера для простого интерпретируемого языка.
## Требования

- CMake ≥ 3.28  
- clang15+
- Bison  
- Flex  
- Python 3 для запуска тестов  

## Сборка проекта
1. Создайте директорию сборки:
```bash
mkdir build && cd build
cmake ..
```
2. Сборка интерпретатора:
```bash
cmake --build .
```
3.  Пример запуска
```bash
./interpreter ../examples/hello_world.lol
```
## Тестирование
Тесты собраны в `tests.py`. Для их запуска из корня проекта используйте таргет run_tests или напрямую Python:
```bash
cmake --build build --target run_tests
```
или
```bash
python3 tests.py
```
