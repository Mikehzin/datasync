#!/usr/bin/expect -f

sudo_password="F@RM4C1A"

# Comando que requer privilégios de root
echo "$sudo_password" | sudo root

estado=$(/opt/mssql-tools/bin/sqlcmd -h -1 -S 127.0.0.1 -U SA -P ERPM@2017 -d PDV -Q 'SET NOCOUNT ON; SELECT ESTADO FROM PARAMETROS')
estado=${estado,,}
estado="$(echo "$estado" | tr -d '[:space:]')"

#Caminho do arquivo fstab
arquivo_fstab="/etc/fstab"


#Lista de Lojas Homolog
lojas_permitidas=("247" "319" "13" "14")
numero_loja=$(/opt/mssql-tools/bin/sqlcmd -h -1 -S 127.0.0.1 -U SA -P ERPM@2017 -d PDV -Q 'SET NOCOUNT ON; SELECT LOJA FROM PARAMETROS')
numero_loja="$(echo "$numero_loja" | tr -d '[:space:]')"

# Verifica se a loja é homolog
if [[ " ${lojas_permitidas[*]} " =~ " ${numero_loja} " ]]; then
    echo "A loja ${numero_loja} esta na lista de lojas homolog"
    novo_caminho_ftp="nasprocfit.intra.drogariasnissei.com.br:/nfs/procftp/$estado/homolog"
    novo_diretorio_montagem="/mnt/procftp"

else
    echo "A loja ${numero_loja} nao eh homolog"
    novo_caminho_ftp="nasprocfit.intra.drogariasnissei.com.br:/nfs/procftp/$estado"
    novo_diretorio_montagem="/mnt/procftp"
fi

#Verifica se o novo diretório de montagem existe
if [ ! -d "$novo_diretorio_montagem" ]; then
    echo "O novo diretório de montagem $novo_diretorio_montagem não existe."
    exit 1
fi

# Verifica se o diretório de montagem é diferente do novo diretório fornecido
if grep -q "$novo_diretorio_montagem" "$arquivo_fstab"; then
    # Edita a linha existente no arquivo fstab com o novo caminho FTP e diretório de montagem
    sed -i "\#nfs.*$novo_diretorio_montagem#s#.*#$novo_caminho_ftp $novo_diretorio_montagem nfs ro,noauto,hard,intr,noexec,users,noatime,nolock,bg,tcp,actimeo=1800 0 0#" "$arquivo_fstab"
    echo "Diretório de montagem e caminho FTP atualizados com sucesso."
else
    echo "Diretório de montagem no arquivo fstab difere do fornecido. Realizando a edição..."
    # Remove a linha com o diretório antigo
    sed -i "\#nfs.*#d" "$arquivo_fstab"
    echo -e "$novo_caminho_ftp $novo_diretorio_montagem nfs ro,noauto,hard,intr,noexec,users,noatime,nolock,bg,tcp,actimeo=1800 0 0" >> "$arquivo_fstab"
    echo "Edição concluída. Diretório de montagem atualizado para $novo_diretorio_montagem."
fi
