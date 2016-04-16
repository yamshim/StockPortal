# coding: utf-8

module Clawler
  module Sources
    module Proxymoo
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://proxy.moo.jp/ja'
      end

      def self.get_proxy_lines(page, driver, wait)
        driver.get(home_url + "/?page=#{page}")
        sleep(1)
        table = wait.until{driver.find_element(tag_name: 'table')}
        trs = wait.until{table.find_elements(tag_name: 'tr')}[1..-1].map(&:text)
        trs.delete('')
        proxy_lines = trs.map{|tr| 'http://' + tr.split(' ')[1]}
        proxy_lines
      end

    end
  end
end