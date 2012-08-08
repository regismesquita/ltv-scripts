#!/usr/bin/env ruby
#CONFIGURE
# Voce não precisa preencher os campos abaixo se tiver o arquivo ltv-account.cfg ;)
#
USUARIO = 'user'
SENHA = 'senha'
# Uso : ruby legenda_downloader.rb "The Matrix"

require 'scanf'
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

  def search_movie(searchParameters)
    if $standalone then puts 'Buscando no site' end
    url = URI.parse('http://legendas.tv/index.php?opcao=buscarlegenda')
    req = Net::HTTP::Post.new('/index.php?opcao=buscarlegenda',@headers)
    req.set_form_data({'txtLegenda'=>searchParameters,'btn_buscar'=>['x'=>0,'y'=>0],'selTipo'=>1,'int_idioma'=>1})
    req['Cookie'] = @cookie
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      lista_de_movies = Array.new
      res.body.each_line do |line|
        if line.match(/abredown/) then
          nome_do_release = line.split(',')[2]
          id_para_download = line.split('abredown(')[1].split('\'')[1]
          lista_de_movies.push({:release_name => nome_do_release , :download_hash => id_para_download}) unless id_para_download.nil?
        end
      end
      return lista_de_movies
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

  def prompt_for_movie_select(movies)
      puts "Filmes encontrados"
      movies_list = Hash[(1..movies.size).zip(movies)]
      movies_list.sort{|x,y|x[0]<=>y[0]}.each{|id,movie| puts "#{id} - #{movie[:release_name]}"}
      choices = nil
      begin
          print "Escolha que legenda baixar: "
          choices = STDIN.gets.split(" ").map{|x| x.to_i}
          choices.delete(0)
          choice = choices.first
      end while choice.class != Fixnum
      exit if choices.first == -1
      return choices.map{|choice| movies_list[choice]}
  end

  def select_movie(movies)
    if movies.size == 0
      puts movies.inspect if ENV['DEBUG']
      puts "Nenhum filme encontrado."
      exit
    elsif movies.size == 1
      return movies
    else
      return prompt_for_movie_select(movies)
    end
  end

  def self.legenda_for(filme)
    downloader = LegendaDownloader.new
    downloader.login
    movies = downloader.search_movie(filme)
    downloader.select_movie(movies).each do |movie|
      downloader.download(movie[:download_hash])
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
