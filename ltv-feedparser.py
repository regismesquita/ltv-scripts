#!/usr/bin/python2

#
# Le os feeds do site legendas.tv e verifica se devemos baixa-los
#

import feedparser
import ConfigParser
import re           # Suporte a expressoes regulares
import sys
import os


FEED_URL = "http://legendas.tv/rss.html"

try:
    # Le as configuracoes da conta do legendas.tv
    config_usuario = ConfigParser.RawConfigParser()
    config_usuario.read('ltv-account.cfg')
    if not config_usuario.has_section("user") or not config_usuario.has_option("user","username") or not config_usuario.has_option("user","password"):
        print "Arquivo ltv-account.cfg nao tem configuracoes de login e senha"
        os._exit(1)
    
    # Armazena o login e a senha do usuario
    ltv_username = config_usuario.get("user","username")
    ltv_password = config_usuario.get("user","password")
        
    # Processa o arquivo RSS do Legendas.tv
    feed = feedparser.parse(FEED_URL)

    # Processa o arquivo de configuracao das series que o usuario quer
    # baixar as legendas
    config = ConfigParser.RawConfigParser()
    config.read('ltv-feeds.cfg')
    
    #
    # Para cada item no feed,
    #   verifica se ele diz respeito a alguma serie do arquivo de configuracao
    #
    for item in feed['entries']:
        for section in config.sections():
            #
            # TODO:
            #   - Verificar se temos os campos necessarios no arquivo de configuracao
            #   - Baixar apenas as series da temporada/episodio iguais ou acima aos
            #     que o usuario configurou
            #   - Armazenar quais legendas ja foram baixadas e nao baixa-las de novo
            #

            section_name = config.get(str(section), "name")
            section_dir  = config.get(str(section), "dir")
            pattern = re.compile(section_name)
            if pattern.match(item['title']):
                print "ltv-downloader.sh \"" + ltv_username + "\" \"" + ltv_password + "\" \"" + item['link'] + "\" \"" + section_dir + "\""

    
except:
    print "Erro ao tentar ler os feeds: ", sys.exc_info()[0]
    raise
    


