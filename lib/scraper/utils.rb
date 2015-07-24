# coding: utf-8
module Scraper
  module Utils
    require 'open-uri'
    require 'nokogiri'
    require 'kconv'
    require 'csv'

    def codes(type_sym)
      translated_codes = {}
      CODE[type_sym.to_s].each do |k, v|
        translated_codes[I18n.t("code.#{type_sym}.#{k}")] = v
      end
      translated_codes
    end

    def c(type_sym, value=:_get_hash)
    if (value == :_get_hash) || value.nil?
      codes(type_sym)
    elsif value.is_a? Array
      value.map{|v| CODE[type_sym.to_s][v.to_s]}
    elsif value.is_a? Symbol
      CODE[type_sym.to_s][value.to_s]
    elsif value.is_a? Integer
      codes(type_sym).key(value)
    elsif value.is_a? String
      codes(type_sym)[value]
    end
  end

  def csym(type_sym, value=:_get_hash)
    if value == :_get_hash
      CODE[type_sym.to_s]
    else
      CODE[type_sym.to_s].key(value).try(:to_sym)
    end
  end

  def ckeys(type_sym)
    return [] unless CODE[type_sym.to_s]
    CODE[type_sym.to_s].keys
  end

  def cvals(type_sym)
    return [] unless CODE[type_sym.to_s]
    CODE[type_sym.to_s].values
  end

  def cstrs(type_sym, value=nil)
    translated_vals = {}
    CODE[type_sym.to_s].each do |k, v|
      translated_vals[k] = I18n.t("code.#{type_sym}.#{k}")
    end
    if value.nil?
      translated_vals
    else
      translated_vals[value.to_s]
    end
  end



  end
end