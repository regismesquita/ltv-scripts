#!/usr/bin/env ruby
#CONFIGURE
# Voce não precisa preencher os campos abaixo se tiver o arquivo ltv-account.cfg ;)
#
USUARIO = 'user'
SENHA = 'senha'
# Uso : ruby legenda_downloader.rb "The Matrix"

require 'net/http'
require 'uri'

class LegendaDownloader


  def initialize
    if File.exists?('ltv-account.cfg')
      File.open('ltv-account.cfg').read.each_line do |line| 
        line = line.split('=')
        if line[0] == 'username' then @login = line[1] end
        if line[0] == 'password' then @senha = line[1] end
      end
    else
      @login = USUARIO
      @senha = SENHA
    end
  end
  def login
    if $standalone then puts 'Logando no site' end
    url = URI.parse('http://legendas.tv/login_verificar.php')
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({'txtLogin'=>@login,'txtSenha'=>@senha})
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      cookie = res.response['set-cookie']
      @cookie = cookie.split(';')[0]
    else
      res.error!
    end
  end
  def buscar(searchParameters)
    if $standalone then puts 'Buscando no site' end
    url = URI.parse('http://legendas.tv/index.php?opcao=buscarlegenda')
    req = Net::HTTP::Post.new('/index.php?opcao=buscarlegenda',@headers)
    req.set_form_data({'txtLegenda'=>searchParameters,'btn_buscar'=>['x'=>0,'y'=>0],'selTipo'=>1,'int_idioma'=>1})
    req['Cookie'] = @cookie
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      lista_de_filmes = Hash.new
      res.body.each_line do |line|
        if line.match(/abredown/) then
          nome_do_release = line.split(',')[2]  
          id_para_download = line.split('abredown(')[1].split('\'')[1]
          lista_de_filmes[nome_do_release] = id_para_download
        end
      end
      lista_de_filmes.delete(nil)
      lista_de_filmes= (1..lista_de_filmes.size).zip(lista_de_filmes)
      lista_de_filmes = Hash[lista_de_filmes]

    else
      raise res.error!
    end

  end
  def get_download_link(hash)
    if $standalone then puts "Legenda sendo baixada" end
    path= "/info.php?d=#{hash}&c=1"
    url = URI.parse('http://legendas.tv' << path)
    req = Net::HTTP::Get.new(path)
    req['Cookie'] = @cookie
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      link = res['location']
      return '/' << link
    else
      raise res.error!
    end
  end

  def download(hash)
    link = get_download_link(hash)
    filename = link.split('/')
    filename = filename[2]
    url = URI.parse('http://legendas.tv' << link)
    req = Net::HTTP::Get.new(link)
    req['Cookie'] = @cookie
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      file = File.open(filename,'wb') 
      file.write(res.body)
      file.close
      if $standalone then puts "Legenda Salva em #{filename}" end
      return res
    else
      raise res.error!
    end


  end
  def self.legenda_for(filme)
    #Pega a primeira legenda encontrada e baixa =P I'm Feeling Lucky.
    baixador = LegendaDownloader.new
    baixador.login
    filmes = baixador.buscar(filme)
    hash_do_filme = filme[1]
    if filmes.size == 0
      puts filmes.inspect if ENV['DEBUG']
      puts "Nenhum filme encontrado."
      exit
    else
      puts "Filmes encontrados"
      filmes.sort{|x,y|x[0]<=>y[0]}.each{|id,filme| puts "#{id} - #{filme[0]}"}
      require 'scanf'
      escolhas = nil
      begin
        print "Escolha que legenda baixar: "
        escolhas = STDIN.gets.split(" ").map{|x| x.to_i}
        escolhas.delete(0)
        escolha = escolhas.first
      end while escolha.class != Fixnum
      exit if escolhas.first == -1
      escolhas.each do |escolha|
        hash_do_filme = filmes[escolha][1]
        baixador.download(hash_do_filme)
      end
    end
  end
end

if ARGV.size != 0
  $standalone = true
  puts "Buscando Legenda para #{ARGV.join(" ")}"
  LegendaDownloader.legenda_for(ARGV.join(" "))
else
  puts "Programa para download de legendas do legendas.tv"
  puts "Uso.: legenda nome do filme"
end
