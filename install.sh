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

## Determinar la hora

date MMDDhhmmYY

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

## Sincronizar espejos y seleccionar perfiles
time emerge --sync --quiet
eselect profile list
eselect profile set X ## La X es el número de perfil, en mi caso sería sin systemd
time emerge -qavuND @world

## Configurar zona horaria
ls /usr/share/zoneinfo
echo "Europe/Madrid" > /etc/timezone
emerge --config sys-libs/timezone-data

## Configurar idioma
nano -w /etc/locale.gen
# Descomentar es_ES.UTF-8 UTF-8
nano -w /etc/env.d/02locale ## Sólo si no existe o si no está configurado
# LANG="es_ES.UTF-8"
# LC_COLLATE="C"
locale-gen
eselect locale list
eselect locale set X ## La X es el número de locale, en mi caso sería es_ES.utf-8
env-update && source /etc/profile && export PS1="(chroot) $PS1"

#### Parte 4ª: instalación y configuración del kernel ####

## Instalar las fuentes
time emerge -qav sys-kernel/gentoo-sources

## Subparte 1ª: instalación manual
time emerge -qav sys-apps/pciutils
cd /usr/src/linux
make menuconfig
## En este punto seleccionar y deseleccionar aquello que se vaya a usar y que no se vaya a usar
make && make modules_install
make install

## Subparte 2ª: genkernel
time emerge -qav sys-kernel/genkernel
nano -w /etc/fstab
# /dev/sda1 /boot ext2 defaults,noatime 0 2
# /dev/sda3 / ext4 defaults,noatime 0 1
# /dev/sda4 /home ext4 defaults,noatime 0 2
genkernel --no-zfs --no-btrfs --menuconfig all
## En este punto seleccionar y deseleccionar aquello que se vaya a usar y que no se vaya a usar
ls /boot/kernel* /boot/initramfs* ## Apuntar los nombres del kernel y del initrd para usarlos más adelante, en el boot

## Configurar los módulos
find /lib/modules/<kernel version>/ -type f -iname '*.o' -or -iname '*.ko' | less
mkdir -p /etc/modules-load.d
nano -w /etc/modules-load.d/network.conf
## Escribir el nombre del módulo a cargar automáticamente, en caso necesario
emerge -qav sys-kernel/linux-firmware net-wireless/broadcom-sta x11-misc/sddm
ip link show
emerge -avn net-misc/netifrc
nano -w /etc/conf.d/net
# config_wlp2s0=”dhcp”
cd /etc/init.d && ln -s net.lo net.wlp2s0 && rc-update add net.wlp2s0 default

#### Parte 5ª: Configuración variada ####

## Contraseña
passwd

## Host
nano -w /etc/conf.d/hostname
# hostname="gentoo"
nano -w /etc/hosts
nano -w /etc/rc.conf
# Cambiar lo necesario, en su caso
nano -w /etc/conf.d/keymaps
# Seleccionar el teclado adecuado
nano -w /etc/conf.d/hwclock
# clock="local" ## Cambiar a UTC o a local según el caso
time emerge -qav app-admin/sysklogd
rc-update add sysklogd default
time emerge -qav sys-process/cronie
rc-update add cronie default
time emerge -qav sys-apps/mlocate
time emerge -qav net-misc/dhcpcd
time emerge -qav net-wireless/iw net-wireless/wpa_supplicant
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
time emerge -qav sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

## Opcional
time emerge -qav app-shells/zsh app-shells/zsh-completions app-shells/gentoo-zsh-completions
chsh -s /bin/zsh

## Finalización
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot

#### Parte 6ª: Consideraciones al usar un LiveCD/DVD de otra distribución ####
## Crear el directorio para gentoo antes de montar las particiones
mkdir /mnt/gentoo
mount /dev/sda3 /mnt/gentoo
mkdir /mnt/gentoo/home
mount /dev/sda4 /mnt/gentoo/home

## Desempaquetar stage3
# tar xvpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
tar xvjpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

## Montar el sistema de archivos proc
# mount --types proc /proc /mnt/gentoo/proc
mount -o bind /proc /mnt/gentoo/proc

## chroot
# chroot /mnt/gentoo /bin/bash
chroot /mnt/gentoo /bin/env -i TERM=$TERM /bin/bash
env-update
source /etc/profile
export PS1="(chroot) $PS1"
