# coding: utf-8

module Clawler
  module Sources
    module Investing
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'http://jp.investing.com'
      end

      def self.get_commodity_url(commodity_name)
        home_url + "/commodities/#{commodity_name}-historical-data"
      end

      def self.get_commodities_info(commodity_name, driver, wait)
        commodity_url = Clawler::Sources::Investing.get_commodity_url(commodity_name)
        driver.get(commodity_url)
        sleep(1)

        wait.until{driver.find_element(id: 'mainPopUpContainer').find_element(class: 'bugCloseIcon')}.click unless driver.find_elements(id: 'mainPopUpContainer').size.zero?
        sleep(0.5)

        js_script = "document.getElementById('picker').setAttribute('value', '1990/01/01 - 2001/05/14')"
        #js_script = "document.getElementById('picker').setAttribute('value', '2010/01/01 - #{scrape_end_date.to_s.gsub('-', '/')}')"
        driver.execute_script(js_script) # wait.untilだめ
        wait.until{driver.find_element(id: 'widget')}.click
        sleep(0.5)

        wait.until{driver.find_element(link_text: '適用')}.click
        select = ::Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'data_interval'))
        select.select_by(:index, 0)
        commodities_info = wait.until{driver.find_element(id: 'curr_table').find_elements(css: 'tr')}[1..-1]
        commodities_info
      end

      def self.get_commodity_line(commodity_info, commodity_code)
        commodity_line = []
        commodity_line << commodity_code
        commodity_data = commodity_info.text.split(' ')
        tmp = commodity_data[0].split(/[^0-9]/)
        commodity_line << trim_to_date("#{tmp[2]}年#{tmp[0]}月#{tmp[1]}日")





        if commodity_data.include?(nil)
          binding.pry
          CLAWL_LOGGER.info(action: commodity_data)
          CLAWL_LOGGER.info(action: 'hoge')
          []
        else





          (1..4).each{|index| commodity_line << trim_to_f(commodity_data[index])}
          commodity_line
        end

      end

    end
  end
end