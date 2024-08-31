# BASES DE DATOS MASIVAS

1 entregable: carga de datos .csv + facturación + hoja de vida. 

## Cómo hacer el PR

### 1. Haz un Fork del Repositorio

Haz un fork de este repositorio para tener tu propia copia del proyecto. Puedes hacerlo haciendo clic en el botón **Fork** en la parte superior derecha de la página del repositorio.

### 2. Clona tu Fork a tu Computadora

Clona el repositorio que acabas de forkear a tu máquina local utilizando Git. Reemplaza `<tu-usuario>` con tu nombre de usuario de GitHub.

```bash
git clone https://github.com/<tu-usuario>/masive_db.git
cd nombre-del-directorio
# Migra hacia la rama pruebas
git checkout pruebas
# Añade lo que vas a subir al github
git add .
git commit -m "Descripción breve de los cambios"
#haz el push
git pull origin pruebas
git push origin pruebas


