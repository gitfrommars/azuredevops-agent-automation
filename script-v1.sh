#!/bin/sh

## Variaveis


serverUrl=https://dev.azure.com/danielcamppos/

PersonalAccessToken=flwvwwfoyljrf56u75h4qjgwisovb5ik7zh7ncgv6sbiwv47kh4a

PoolName="Default"

AgentName="Agent job"

USER=usr_agente

FOLDER=agent_prd

AGENTRELEASE="$(curl -s https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")')"

AGENTURL="https://vstsagentpackage.azureedge.net/agent/${AGENTRELEASE}/vsts-agent-linux-x64-${AGENTRELEASE}.tar.gz"


echo "Verificando instalacao pacote docker"


pkg="docker"


if rpm -q $pkg
then

echo "$pkg instalado"

else

echo "$pkg nao instalado. Iniciando instalacao"

sudo yum install docker -y
sleep 3
echo "{insecure-registries: [172.30.0.0/16]}" | sudo tee /etc/docker/daemon.json
sudo systemctl start docker
sudo systemctl enable docker

fi



echo "Verificando instalacao pacote openshift-clients"

pkg="openshift-clients"

if rpm -q $pkg
then

echo "$pkg instalado"

else

echo "$pkg nao instalado. Iniciando instalacao"

sudo yum install openshift-origin-client-tools -y

fi



echo "Verificando instalacao pacote telnet"

pkg="telnet"

if rpm -q $pkg
then

echo "$pkg instalado"

else

echo "$pkg nao instalado. Iniciando instalacao"

sudo yum install telnet -y

fi


echo "Verificando instalacao pacote wget"

pkg="wget"

if rpm -q $pkg
then

echo "$pkg instalado"

else

echo "$pkg nao instalado. Iniciando instalacao"

sudo yum install wget -y

fi



echo -n "Criando usuario ..."
sudo useradd $USER

echo -n "Inserindo usuario no grupo docker ..."
sudo groupadd docker
sudo usermod -aG dockerroot $USER
sudo gpasswd -a $USER docker


echo -n "Inserindo usuario no arquivo /etc/sudoers ..."
sudo cp /etc/sudoers /tmp/sudoers.bak
sudo echo "$USER ALL=(ALL) NOPASSWD:ALL
Defaults:$USER !requiretty
" >> /tmp/sudoers.bak
sudo visudo -cf /tmp/sudoers.bak


if [ $? -eq 0 ]; then

sudo cp /tmp/sudoers.bak /etc/sudoers

else

echo "Nao foi possivel inserir o usuario no arquivo /etc/sudoers"

fi


echo -n "Atualizando arquivo /etc/hosts ..."



echo -n "Criando pasta de trabalho ..."
sudo mkdir -p /home/$USER/agente
sudo chown $USER:$USER /home/$USER -R
sudo chmod 777 /home/$USER/ -R

echo -n "Instalando agente VSTS ..."
wget -P /home/$USER/agente/ https://vstsagentpackage.azureedge.net/agent/2.157.0/vsts-agent-linux-x64-2.157.0.tar.gz
cd /home/$USER/agente
tar xvzf vsts-agent-linux-x64-2.157.0.tar.gz
sudo chmod 777 . -R
sudo ./bin/installdependencies.sh
sudo -u usr_agente ./config.sh --unattended --url $serverUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --acceptTeeEula --work ./_work --runAsService


echo "Servico Instalado"

sudo ./svc.sh install

echo "Servico Iniciado"

sudo ./svc.sh start


echo "Instalacao realizada com sucesso!!"

exit 0

