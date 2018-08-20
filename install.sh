# Referencia: https://wiki.gentoo.org/wiki/Handbook:AMD64
###########################################################
#### Parte 1ª: iniciar con Gentoo LiveDVD ####

# La configuración de la red se hace con el administrador por defecto, y el particionado, en su caso, con el gestor de particiones
# por defecto, así como la creación de los sistemas de archivos.

## Montar las particiones
mount /dev/sda3 /mnt/gentoo
mkdir /mnt/gentoo/home
mount /dev/sda4 /mnt/gentoo/home

#### Parte 2ª: instalar los paquetes del stage ####

## Descargar el paquete stage3
cd /mnt/gentoo
wget -c ftp://ftp.uni-erlangen.de/pub/mirrors/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-XXXXXX.tar.xz
# Las XXXX hacen referencia al código alfanumérico del paquete en cuestión, imposible reproducirlo porque cambia cada día o semana
tar xvpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

## Modificar make.conf
nano -w /mnt/gentoo/etc/portage/make.conf
# CFLAGS="-march=native -O2 -pipe"
# CXXFLAGS="${CFLAGS}"
# MAKEOPTS="-j5" ## -j debe ir seguido del número de núcleos del ordenador + 1, por ejemplo, si tiene 4 núcleos será -j5.
# USE="networkmanager pulseaudio alsa"
# INPUT_DEVICES="evdev keyboard mouse"
# VIDEO_CARDS="intel i915" ## cambiar la tarjeta por la/s que tenga el ordenador donde se instalará.
# LANG="es_ES.UTF-8"
# LINGUAS="es"

## Elegir los espejos
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf

## Crear el repositorio ebuild
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
#(El archivo debe contener lo siguiente:

#[DEFAULT]
#main-repo = gentoo

#[gentoo]
#location = /usr/portage
#sync-type = rsync
#sync-uri = rsync://rsync.gentoo.org/gentoo-portage
#auto-sync = yes
#sync-rsync-verify-jobs = 1
#sync-rsync-verify-metamanifest = yes
#sync-rsync-verify-max-age = 24
#sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
#sync-openpgp-key-refresh-retry-count = 40
#sync-openpgp-key-refresh-retry-overall-timeout = 1200
#sync-openpgp-key-refresh-retry-delay-exp-base = 2
#sync-openpgp-key-refresh-retry-delay-max = 60
#sync-openpgp-key-refresh-retry-delay-mult = 4
#)

#### Parte 3ª: cambiar de sistema ####

## Copiar la información DNS y montar los sistemas de archivos necesarios
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

## chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

## Si al crear las particiones en la parte 1ª no se creó una partición swap, realizar los siguientes pasos
fallocate -l 2048M /swapfile ## en mi caso pongo 2048 megas.
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

## Crear y montar la partición /boot (BIOS) o /boot/efi (UEFI)
mount /dev/sda1 /boot
mkdir /boot/efi
mount /dev/sda2 /boot/efi
