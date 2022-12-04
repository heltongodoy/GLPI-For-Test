#!/bin/bash

# Removendo pacotes NTP
apt purge ntp
# Instalar pacotes OpenNTPD
apt install -y openntpd
# Parando Serviço OpenNTPD
service openntpd stop
# Configurar Timezone padrão do Servidor
dpkg-reconfigure tzdata
# Adicionar servidor NTP.BR
echo "servers pool.ntp.br" > /etc/openntpd/ntpd.conf
# Habilitar e Iniciar Serviço OpenNTPD
systemctl enable openntpd
systemctl start openntpd
# PACOTES MANIPULAÇÃO DE ARQUIVOS
apt install -y xz-utils bzip2 unzip curl
# Instalar dependências no sistema
apt install -y apache2 libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2}
# Criar arquivo com conteúdo
echo -e "<Directory \"/var/www/html/glpi\">\nAllowOverride All\n</Directory>" > /etc/apache2/conf-available/glpi.conf
# Habilita a configuração criada
a2enconf glpi.conf
# Reinicia o servidor web considerando a nova configuração
systemctl restart apache2
# BAIXAR PACOTE GLPi
wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.5/glpi-10.0.5.tgz | tar -zxv -C /var/www/html/
# AJUSTAR PERMISSÕES DE ARQUIVOS
chown www-data. /var/www/html/glpi -Rf
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;
# Instalando o Serviço MySQL
apt install -y mariadb-server
# Criando base de dados
mysql -e "create database glpidb character set utf8" 
# Criando usuário
mysql -e "create user 'admin'@'localhost' identified by '123456'"
# Dando privilégios ao usuário
mysql -e "grant all privileges on glpidb.* to 'admin'@'localhost' with grant option";
# Habilitando suporte ao timezone no MySQL/Mariadb
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -p -u root mysql
# Permitindo acesso do usuário ao TimeZone
mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'admin'@'localhost';"
# Forçando aplicação dos privilégios
mysql -e "FLUSH PRIVILEGES;"
# Comando de instalação do Banco de Dados via Console
php /var/www/html/glpi/bin/console glpi:database:install --db-host=localhost --db-name=glpidb --db-user=admin --db-password=123456
# Reajustando o acesso ao usuário do Apache
chown www-data. /var/www/html/glpi/files -Rf
hostname -I
# Criar entrada no agendador de tarefas do Linux
echo -e "* *\t* * *\troot\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab
# Reiniciar agendador de tarefas para ler as novas configurações
service cron restart
# Remover o arquivo de instalação do sistema
rm -Rf /var/www/html/glpi/install/install.php
