vfio_mld="/etc/modules-load.d/vfio.conf"
vfio_md="/etc/modprobe.d/vfio.conf"
blacklist_md="/etc/modprobe.d/blacklist.conf"

#AREA DE FACIL DEBUG, NÃO MEXA!
#vfio_mld="/home/$USER/arquivo.txt"
#vfio_md="/home/$USER/arquivo.txt"
#blacklist_md="/home/$USER/arquivo.txt"

#É preciso habilitar IGFX na BIOS e ativar VT-d + IOMMU, e é 100% baseado com ferramentas e utilitarios Fedora. 
#$ sudo dnf install virt-manager virt-install libvirt bridge-utils qemu-kvm)
#$ sudo systemctl enable --now libvirtd)

#E é preciso adicionar dentro das linhas GRUB_CMDLINE_LINUX="" isso: intel_iommu=on iommu=pt
#E faça a checagem se o IOMMU está ativo: sudo dmesg | grep -e DMAR -e IOMMU

#em sudo nano /etc/libvirt/qemu.conf adicione:
#user = "sakaki"
#group = "sakaki"

confirm.vfio(){
    while true; do
        clear
        echo -e "Esses diretorios serão modificados:\n"
        echo -e "$vfio_mld\n$vfio_md\n$blacklist_md\n"
        echo -e "[C]onfirmar\n[R]ecusar\n"
        read -p "> " confirmInput
        if [[ "$confirmInput" == [Cc] ]]; then
            break
        elif [[ "$confirmInput" == [Rr] ]]; then
            echo "Recusado pelo usuario."
            exit 1
        else
            echo "Opção Invalida!"
            sleep 1.5
        fi
    done
}

active.vfio(){
    #vfio_mld:
    echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" | sudo tee $vfio_mld
    #vfio_md:
    echo -e "options vfio-pci ids=10de:13c2,10de:0fbb" | sudo tee $vfio_md
    #blacklist_md:
    echo -e "blacklist nouveau\nblacklist nvidia\nblacklist nvidia_drm\nblacklist nvidia_modeset" | sudo tee $blacklist_md
    #dracut_update
    #sudo dracut -f
}

while true; do
clear
echo -e "[VFIO.Switch] - Opções:\n"
echo -e "[A]tivar\n[D]esativar\n"
read -p "> " mainInput
case "$mainInput" in
    [Aa])
        confirm.vfio
        if [[ "$confirmInput" == [Cc] ]]; then
            active.vfio
            lspci -nnk | grep -i nvidia -A3
            exit 1
        else
            echo "Algo não deveria TER ACONTECIDO???"
        fi
    ;;
    [Dd])
        sudo rm -rf $vfio_mld $vfio_md $blacklist_md
        echo "Desativado com sucesso!"
	    exit 1
    ;;
    *)
        echo "Opção Invalida!"
        sleep 1.5
    ;;
esac
done