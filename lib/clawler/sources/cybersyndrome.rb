# coding: utf-8

module Clawler
  module Sources
    module Cybersyndrome
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://www.cybersyndrome.net'
      end

      def self.get_proxy_lines(page, driver, wait)
        driver.get(home_url + "/search.cgi?q=&a=ABCD&f=s&s=new&n=500&p=#{page}")
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