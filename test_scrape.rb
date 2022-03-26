# rubocop:disable all
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'timeout'
require 'active_support/all'

CSV.foreach("sample.csv") do |row|
  next unless row[3]
  Timeout.timeout(1) do
    fd = URI.open(row[3])
    html = fd.read
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

    # All Rights Reservedが含まれている要素がある場合
    search_condition = "//*[contains(text(), \"All Rights Reserved\")] | //*[contains(text(), \"All rights reserved\")] | //*[contains(text(), \"All Right Reserved\")] | //*[contains(text(), \"All right reserved\")] | //*[contains(text(), \"all rights reserved\")] | //*[contains(text(), \"all right reserved\")] | //*[contains(text(), \"ALL RIGHTS RESERVED\")]"
    element = doc.xpath("#{search_condition}")
    if element.present?
      text = element.text

      #Javascriptのコードらしきものが含まれる場合は取得しない
      next if "#{text}" =~ /\=/ || "#{text}" =~ /;/ || "#{text}" =~ /document./

      pre_match_text = text.match(/All Righ(t|ts) Reserved/i)&.pre_match
      en_company_name = pre_match_text

      # copyrightが記載されている場合
      copyright_text = en_company_name.match(/copyright/i)
      en_company_name = copyright_text.post_match if copyright_text

      # ©が記載されている場合
      copyright_mark = en_company_name.match(/©/)
      en_company_name = copyright_mark.post_match if copyright_mark

      # (c)が記載されている場合
      bracket_c_mark = en_company_name.match(/\(c\) |（C）/i)
      en_company_name = bracket_c_mark.post_match if bracket_c_mark

      # cが記載されている場合
      c_mark = en_company_name.match(/( |　)c( |　)/i)
      en_company_name = c_mark.post_match if c_mark

      # 年数が記載されている場合
      years_number = en_company_name.match(/(\d{4}(| |　)(-|–|ー)(| |　)\d{4})|(\d{4}.)|(\d{4})/)
      en_company_name = years_number.post_match if years_number

      # 日本語・その他文字が含まれているか確認
      next if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々]|\|)/

      # 空白がないか確認
      next if en_company_name.blank?

      puts en_company_name.gsub(/　/," ").strip
      next
    end

    # ©が含まれている要素がある場合
    search_condition = "//*[contains(text(), \"©\")]"
    element = doc.xpath("#{search_condition}")
    if element.present?
      text = element.text

      # &nbspが含まれる場合は取得しない
      next if "#{text}" =~ /\u{C2A0}/

      # All Rights Reservedが含まれる場合は取得しない
      next if "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)

      #Javascriptのコードらしきものが含まれる場合は取得しない
      next if "#{text}" =~ /\=/ || "#{text}" =~ /;/ || "#{text}" =~ /document./

      post_match_text = text.match(/©/).post_match
      en_company_name = post_match_text

      # 年数が記載されている場合
      years_number = en_company_name.match(/(\d{4}(| |　)(-|–|ー)(| |　)\d{4})|(\d{4}.)|(\d{4})/)
      en_company_name = years_number.post_match if years_number

      # 会社名を重複して取得している場合
      copyright_mark = en_company_name.match(/©/)
      en_company_name = copyright_mark.pre_match if copyright_mark

      # 日本語・その他文字が含まれているか確認
      next if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々]|\|)/

      # 空白がないか確認
      next if en_company_name.blank?

      puts en_company_name.gsub(/　/," ").strip
      next
    end

    # (c)が含まれている要素がある場合
    search_condition = "//*[contains(text(), \"(c)\")] | //*[contains(text(), \"(C)\")]"
    element = doc.xpath("#{search_condition}")
    if element.present?
      text = element.text

      # &nbspが含まれる場合は取得しない
      next if "#{text}" =~ /\u{C2A0}/

      # All Rights Reservedが含まれる場合は取得しない
      next if "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)

      #Javascriptのコードらしきものが含まれる場合は取得しない
      next if "#{text}" =~ /\=/ || "#{text}" =~ /;/ || "#{text}" =~ /document./

      post_match_text = text.match(/\(c\) |（C）/i).post_match
      en_company_name = post_match_text

      # 年数が記載されている場合
      years_number = en_company_name.match(/(\d{4}(| |　)(-|–|ー)(| |　)\d{4})|(\d{4}.)|(\d{4})/)
      en_company_name = years_number.post_match if years_number

      # 会社名を重複して取得している場合
      bracket_c_mark = en_company_name.match(/\(c\) |（C）/i)
      en_company_name = bracket_c_mark.post_match if bracket_c_mark

      # 日本語・その他文字が含まれているか確認
      next if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々]|\|)/

      # 空白がないか確認
      next if en_company_name.blank?

      puts en_company_name.gsub(/　/," ").strip
      next
    end

    # copyrightが含まれている要素がある場合
    search_condition = "//*[contains(text(), \"Copyright\")] | //*[contains(text(), \"copyright\")]"
    element = doc.xpath("#{search_condition}")
    if element.present?
      text = element.text

      # &nbspが含まれる場合は取得しない
      next if "#{text}" =~ /\u{C2A0}/

      # All Rights Reservedが含まれる場合は取得しない
      next if "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)

      #Javascriptのコードらしきものが含まれる場合は取得しない
      next if "#{text}" =~ /\=/ || "#{text}" =~ /;/ || "#{text}" =~ /document./

      post_match_text = text.match(/copyright/i).post_match
      en_company_name = post_match_text

      # 年数が記載されている場合
      years_number = en_company_name.match(/(\d{4}(| |　)(-|–|ー)(| |　)\d{4})|(\d{4}.)|(\d{4})/)
      en_company_name = years_number.post_match if years_number

      # 会社名を重複して取得している場合
      copyright_text = en_company_name.match(/copyright/i)
      en_company_name = copyright_text.post_match if copyright_text

      # 日本語・その他文字が含まれているか確認
      next if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々]|\|)/

      # 空白がないか確認
      next if en_company_name.blank?

      puts en_company_name.gsub(/　/," ").strip
      next
    end
  end
  rescue => e
    puts row[1]
    puts e
    next
end
