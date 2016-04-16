capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Mac OS X 10.6) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.79 Safari/535.11')
driver = ::Selenium::WebDriver.for(:phantomjs, :desired_capabilities => capabilities)
wait = ::Selenium::WebDriver::Wait.new(timeout: 10)

begin
  companies = ::Company.all.sort_by{|c| c.company_code}
  companies.each do |company|
    p company.name
    driver.get('https://www.sbisec.co.jp/ETGate')
    sleep(0.5)

    e1 = wait.until{driver.find_element(id: 'srchK')}
    wait.until{e1.find_element(id: 'top_stock_sec')}.send_keys(company.company_code.to_s)
    wait.until{e1.find_element(tag_name: 'a')}.click
    sleep(0.5)

    next if wait.until{driver.find_elements(tag_name: 'table')[1]}.text =~ /対象銘柄はありません。/
    company_name = wait.until{driver.find_element(name: 'FormKabuka').find_element(tag_name: 'h3')}.text.gsub(/ （.+）/, '')
    company.name = company_name
    company.save!
    p company.name
  end
rescue => ex
  p ex.message
end