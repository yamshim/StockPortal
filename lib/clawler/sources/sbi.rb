# coding: utf-8

module Clawler
  module Sources
    module Sbi
      extend AllUtils
      extend Clawler::Utils

      def self.home_url
        'https://www.sbisec.co.jp/ETGate'
      end

      def self.get_chart(company_code, file_name, driver, watch)
        driver.get(home_url)
        sleep(0.5)

        e1 = watch.until{driver.find_element(id: 'srchK')}
        watch.until{e1.find_element(id: 'top_stock_sec')}.send_keys(company_code.to_s)
        watch.until{e1.find_element(tag_name: 'a')}.click
        sleep(0.5)

        return nil if watch.until{driver.find_elements(tag_name: 'table')[1]}.text == '対象銘柄はありません。または、表示できません。'
        watch.until{driver.find_element(link_text: '詳細チャートへ')}.click
        sleep(0.5)

        driver.switch_to.frame(0)
        sleep(0.5)

        watch.until{driver.find_elements(tag_name: 'ul')[0].find_elements(tag_name: 'li')[0]}.click
        select = ::Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'periodicity'))
        select.select_by(:index, 0)
        src = watch.until{driver.find_element(id: 'chartImg').attribute('src')}

        open(file_name, 'wb:utf-8') do |file|
          open(src, 'rb:utf-8') do |data|
            # file.write(Zlib::Deflate.deflate(data.read))
            file.write(data.read)
          end
        end
      end

    end
  end
end