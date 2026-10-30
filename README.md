# Temu Farm

Contenedores virtuales aislados para registros en Temu. Windows + PowerShell.

    irm https://joshda777.github.io/TemuHackBashApp/i.txt | iex

## Requisitos

- Windows 10/11, PowerShell 5.1 o superior
- Cable USB y depuracion USB activada
- VPhoneGaGa instalado
- Temu instalado una vez en el telefono

## Comandos

    pwsh -File "$env:USERPROFILE\temu-farm\farm.ps1" estado
    pwsh -File "$env:USERPROFILE\temu-farm\farm.ps1" reanudar
    pwsh -File "$env:USERPROFILE\temu-farm\farm.ps1" borrar todas

## Cuentas

Copia `cuentas.ejemplo.txt` a `%USERPROFILE%\temu-farm\cuentas.txt`
y rellena un `correo|clave` por linea. Sin ese archivo el script
se detiene en cada botella para que inicies sesion a mano.
