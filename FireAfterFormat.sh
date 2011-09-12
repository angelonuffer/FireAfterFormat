#!/bin/bash

# Mandinga para pegar o diretório onde o script foi executado
FOLDER=$(cd $(dirname $0); pwd -P)

# Pegando arquitetura do sistema. Valores de retorno: '32-bit' ou '64-bit'
arquitetura=`file /bin/bash | cut -d' ' -f3`

vim=0

#================================ Menu =========================================

# Instala o dialog
sudo apt-get install -y dialog > /dev/null

opcoes=$( dialog --stdout --separate-output                                                                 \
    --title "BernardoFire afterFormat - Pós Formatação para Ubuntu"                                   \
    --checklist 'Selecione os softwares que deseja instalar:' 0 0 0                                         \
    Desktop         "Muda \"Área de Trabalho\" para \"Desktop\" *(Apenas ptBR)"                         ON  \
    Monaco          "Adiciona fonte Monaco e seleciona para o Terminal"				        ON  \
    SSH             "SSH server e client"                                                               ON  \
    Python          "Ambiente para desenvolvimento com python"                                          ON  \
    VIM             "Editor de texto"			                                                ON  \
    Refactoring     "Conjunto de scripts para refatoração de código"                                    ON  \
    Git             "Sistema de controle de versão + configurações úteis"                               ON  \
    GitMeldDiff     "Torna o Meld o software para visualização do diff do git"                          ON  \
    Terminator      "Terminal alternativo ao gnome-terminal"                                            ON  \
    Django	    "Framework web escrito em Python"							ON  \
    Media           "Codecs, flashplayer (32 ou 64 bits), JRE e compactadores de arquivos"              ON  \
    XChat           "Cliente IRC"                                                                       ON  \
    GoogleChrome    "Navegador web Google Chrome"                                                       ON  )

#=============================== Processamento =================================

# Termina o programa se apertar cancelar
[ "$?" -eq 1 ] && exit 1

echo "$opcoes" |
while read opcao
do
    if [ "$opcao" = 'Desktop' ]
    then
        mv $HOME/Área\ de\ Trabalho $HOME/Desktop
        sed "s/"Área\ de\ Trabalho"/"Desktop"/g" $HOME/.config/user-dirs.dirs  > /tmp/user-dirs.dirs.modificado
        mv /tmp/user-dirs.dirs.modificado $HOME/.config/user-dirs.dirs
        xdg-user-dirs-gtk-update
        xdg-user-dirs-update
    fi

    [ "$opcao" = 'SSH' ] && sudo apt-get install -y openssh-server openssh-client

    if [ "$opcao" = 'Monaco' ]
    then
        sudo mkdir /usr/share/fonts/macfonts
        sudo wget -O /usr/share/fonts/macfonts/Monaco_Linux.ttf http://github.com/downloads/hugomaiavieira/afterFormat/Monaco_Linux.ttf --no-check-certificate
        sudo fc-cache -f -v
        # Configura para o terminal
        `gconftool-2 --set /apps/gnome-terminal/profiles/Default/use_system_font -t bool false`
        `gconftool-2 --set /apps/gnome-terminal/profiles/Default/font -t str Monaco\ 10`
    fi

    if [ "$opcao" = 'Python' ]
    then
        sudo apt-get install -y ipython python-dev

        wget -O /tmp/distribute_setup.py http://python-distribute.org/distribute_setup.py
        sudo python /tmp/distribute_setup.py

        sudo easy_install pip
        sudo pip install virtualenv

        sudo pip install virtualenvwrapper
        mkdir -p $HOME/.virtualenvs
        echo "export WORKON_HOME=\$HOME/.virtualenvs" >> $HOME/.bashrc
        echo "source /usr/local/bin/virtualenvwrapper.sh"  >> $HOME/.bashrc
    fi

    if [ "$opcao" = 'VIM' ]
    then
        sudo apt-get install -y vim
        vim=1
    fi
    if [ "$opcao" = 'Refactoring' ]
    then
        wget -O /tmp/refactoring-scripts.tar.gz http://github.com/hugomaiavieira/refactoring-scripts/tarball/master --no-check-certificate
        tar zxvf /tmp/refactoring-scripts.tar.gz -C /tmp
        /tmp/hugomaiavieira-refactoring-scripts*/install.sh
    fi

    if [ "$opcao" = 'Media' ]
    then
        # A referência para a instalação desses pacotes foi o http://ubuntued.info/

        # Adiciona o repositório Medibuntu
        sudo wget --output-document=/etc/apt/sources.list.d/medibuntu.list http://www.medibuntu.org/sources.list.d/$(lsb_release -cs).list &&
             sudo apt-get update &&
             sudo apt-get -y --allow-unauthenticated install medibuntu-keyring &&
             sudo apt-get update

        # Adiciona o repositório Partner. É um repositório oficial que contém os
        # pacotes de instalação do Java da Sun.
        sudo add-apt-repository "deb http://archive.canonical.com/ubuntu natty partner" && sudo apt-get update

        # Pacotes de codecs de áudio e vídeo
        sudo apt-get install -y non-free-codecs libdvdcss2 faac faad ffmpeg    \
             ffmpeg2theora flac icedax id3v2 lame libflac++6 libjpeg-progs     \
             libmpeg3-1 mencoder mjpegtools mp3gain mpeg2dec mpeg3-utils       \
             mpegdemux mpg123 mpg321 regionset sox uudeview vorbis-tools x264

        # Pacotes de compactadores de ficheiros
        sudo apt-get install -y arj lha p7zip p7zip-full p7zip-rar rar unrar unace-nonfree

        if [ "$arquitetura" = "32-bit" ]
        then
            # Instalar o flash e o java
            sudo apt-get install -y flashplugin-nonfree sun-java6-fonts sun-java6-jre sun-java6-plugin
        elif [ "$arquitetura" = "64-bit" ]
        then
            # Adiciona o repositório oficial da Adobe para o Flash
            sudo add-apt-repository ppa:sevenmachines/flash && sudo apt-get update
            # Remover qualquer versão do Flashplayer 32 bits para que não haja conflitos
            sudo apt-get purge -y flashplugin-nonfree gnash gnash-common mozilla-plugin-gnash swfdec-mozilla
            # Instalar o flash e o java
            sudo apt-get install -y flashplugin64-installer sun-java6-fonts sun-java6-jre sun-java6-plugin
        fi
    fi

    if [ "$opcao" = 'GoogleChrome' ]
    then
        if [ "$arquitetura" = '32-bit' ]
        then
            wget -O /tmp/google-chrome-stable-i386.deb http://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb
            sudo dpkg -i /tmp/google-chrome-stable-i386.deb
        elif [ "$arquitetura" = '64-bit' ]
        then
            wget -O /tmp/google-chrome-stable-amd64.deb http://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo dpkg -i /tmp/google-chrome-stable-amd64.deb
        fi
    fi

    if [ "$opcao" = 'GitMeldDiff' ]
    then
        git --version 2> /dev/null
        if ! [ "$?" -eq 127 ]
        then
            sudo apt-get install -y meld
            touch $HOME/.config/git_meld_diff.py
            echo "#!/bin/bash" >> $HOME/.config/git_meld_diff.py
            echo "meld \"\$5\" \"\$2\"" >> $HOME/.config/git_meld_diff.py
            chmod +x $HOME/.config/git_meld_diff.py
            git config --global diff.external $HOME/.config/git_meld_diff.py
        else
            dialog --title 'Aviso' \
            --msgbox 'Para tornar o Meld o software para visualização do diff do git, o git deve estar instalado. Para isto, rode novamente o script marcando as opções Git e GitMeldDiff.' \
            0 0
        fi
    fi


    [ "$opcao" = 'XChat' ]              && sudo apt-get install -y xchat

    [ "$opcao" = 'Terminator' ]		&& sudo apt-get install -y Terminator

    [ "$opcao" = 'Django' ]		&& sudo pip install -U django

done

dialog --title 'Aviso' \
       --msgbox 'Instalação concluída!' \
0 0

