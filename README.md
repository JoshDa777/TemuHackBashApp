# Temu Farm

Contenedores virtuales aislados para registros en Temu. Sin root.

    curl -sL https://joshda777.github.io/TemuHackBashApp/i.sh | bash

## Motores

- `clones` (por defecto): usa un contenedor tipo VirtualApp. Hasta 50 botellas vivas, ~200 MB cada una.
- `usuarios`: usuarios de Android. Mas estable con Google, pero tope 4-8.

## Requisitos

- Android 11+
- VPhoneGaGa instalado (motor clones)
- Temu instalado una vez en el telefono
- Depuracion inalambrica activa

## Comandos

    bash ~/temu-farm/farm.sh estado
    bash ~/temu-farm/farm.sh reanudar
    bash ~/temu-farm/farm.sh borrar todas
