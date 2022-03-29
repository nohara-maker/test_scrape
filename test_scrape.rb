# rubocop:disable all
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'timeout'
require 'charlock_holmes'
require 'kconv'
require 'active_support/all'

# data_list = CSV.read('hogehoge.csv')
bom = "\uFEFF"
path = 'master.csv'
detection = CharlockHolmes::EncodingDetector.detect(File.read(path))
encoding = detection[:encoding] == 'Shift_JIS' ? 'CP932' : detection[:encoding]
csv_file = CSV.generate(bom, :force_quotes => true) do |csv|
  CSV.foreach(path, encoding: "#{encoding}:UTF-8", headers: true) do |row|
    next unless row[4]
    Timeout.timeout(10) do
      fd = URI.open(row[4], "r:binary")
      html = fd.read
      doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

      # All Rights Reservedが含まれている要素がある場合
      search_condition = "//*[contains(text(), \"All Rights Reserved\")] | //*[contains(text(), \"All rights reserved\")] | //*[contains(text(), \"All Right Reserved\")] | //*[contains(text(), \"All right reserved\")] | //*[contains(text(), \"all rights reserved\")] | //*[contains(text(), \"all right reserved\")] | //*[contains(text(), \"ALL RIGHTS RESERVED\")]"
      element = doc.xpath("#{search_condition}")
      if element.present?
        text = element.text

        #Javascriptのコードらしきものが含まれる場合は取得しない
        if "#{text}" =~ /\=|;|document./
          csv << [row[0], nil]
          next
        end

        pre_match_text = text.match(/All Righ(t|ts) Reserved/i)&.pre_match
        en_company_name = pre_match_text

        # copyrightが記載されている場合
        copyright_text = en_company_name.match(/copyright/i)
        en_company_name = copyright_text.post_match if copyright_text

        # ©が記載されている場合
        copyright_mark = en_company_name.match(/©/)
        en_company_name = copyright_mark.post_match if copyright_mark

        # (c)が記載されている場合
        bracket_c_mark = en_company_name.match(/\(c\)|（C）/i)
        en_company_name = bracket_c_mark.post_match if bracket_c_mark

        # cが記載されている場合
        c_mark = en_company_name.match(/( |　)c( |　)/i)
        en_company_name = c_mark.post_match if c_mark

        # 年数が記載されている場合
        years_number = en_company_name.match(/(20|19|18)..(| |　)(-|–|ー)(| |　)(20|19|18)..(.|)|(20|19)(\d{2})(.|)/)
        en_company_name = years_number.post_match if years_number

        # 日本語・その他文字が含まれているか確認
        if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々])|\||(\d{4})|\"/ || en_company_name.blank? || "#{en_company_name}" =~ /(-|ー)( |　)(.*)|(.*)( |　)(-|ー)/i
          csv << [row[0], nil]
          next
        end

        csv << [row[0], en_company_name]
        next
      end

      # ©が含まれている要素がある場合
      search_condition = "//*[contains(text(), \"©\")]"
      element = doc.xpath("#{search_condition}")
      if element.present?
        text = element.text

        # &nbsp, All Rights Reserved, JSのコードらしきものが含まれる場合は取得しない
        if "#{text}" =~ /\u{C2A0}|\=|;|document./ || "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)
          csv << [row[0], nil]
          next
        end

        post_match_text = text.match(/©/).post_match
        en_company_name = post_match_text

        # 年数が記載されている場合
        years_number = en_company_name.match(/(20|19|18)..(| |　)(-|–|ー)(| |　)(20|19|18)..(.|)|(20|19)(\d{2})(.|)/)
        en_company_name = years_number.post_match if years_number

        # 会社名を重複して取得している場合
        copyright_mark = en_company_name.match(/©/)
        en_company_name = copyright_mark.pre_match if copyright_mark

        # 日本語・その他文字が含まれているか確認
        if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々])|\||(\d{4})|\"/ || en_company_name.blank? || "#{en_company_name}" =~ /(-|ー)( |　)(.*)|(.*)( |　)(-|ー)/i
          csv << [row[0], nil]
          next
        end

        csv << [row[0], en_company_name]
        next
      end

      # (c)が含まれている要素がある場合
      search_condition = "//*[contains(text(), \"(c)\")] | //*[contains(text(), \"(C)\")]"
      element = doc.xpath("#{search_condition}")
      if element.present?
        text = element.text

        # &nbsp, All Rights Reserved, JSのコードらしきものが含まれる場合は取得しない
        if "#{text}" =~ /\u{C2A0}|\=|;|document./ || "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)
          csv << [row[0], nil]
          next
        end

        post_match_text = text.match(/\(c\)|（C）/i).post_match
        en_company_name = post_match_text

        # 年数が記載されている場合
        years_number = en_company_name.match(/(20|19|18)..(| |　)(-|–|ー)(| |　)(20|19|18)..(.|)|(20|19)(\d{2})(.|)/)
        en_company_name = years_number.post_match if years_number

        # 会社名を重複して取得している場合
        bracket_c_mark = en_company_name.match(/\(c\)|（C）/i)
        en_company_name = bracket_c_mark.post_match if bracket_c_mark

        # 日本語・その他文字が含まれているか確認
        if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々])|\||(\d{4})|\"/ || en_company_name.blank? || "#{en_company_name}" =~ /(-|ー)( |　)(.*)|(.*)( |　)(-|ー)/i
          csv << [row[0], nil]
          next
        end

        csv << [row[0], en_company_name]
        next
      end

      # copyrightが含まれている要素がある場合
      search_condition = "//*[contains(text(), \"Copyright\")] | //*[contains(text(), \"copyright\")]"
      element = doc.xpath("#{search_condition}")
      if element.present?
        text = element.text

        # &nbsp, All Rights Reserved, JSのコードらしきものが含まれる場合は取得しない
        if "#{text}" =~ /\u{C2A0}|\=|;|document./ || "#{text}" =~ /all/i && ("#{text}" =~ /righ(t|ts)/i || "#{text}" =~ /reserved/i)
          csv << [row[0], nil]
          next
        end

        post_match_text = text.match(/copyright/i).post_match
        en_company_name = post_match_text

        # 年数が記載されている場合
        years_number = en_company_name.match(/(20|19|18)..(| |　)(-|–|ー)(| |　)(20|19|18)..(.|)|(20|19)(\d{2})(.|)/)
        en_company_name = years_number.post_match if years_number

        # 会社名を重複して取得している場合
        copyright_text = en_company_name.match(/copyright/i)
        en_company_name = copyright_text.post_match if copyright_text

        # 日本語・その他文字が含まれているか確認
        if "#{en_company_name}" =~ /(?:\p{Hiragana}|\p{Katakana}|[一-龠々])|\||(\d{4})|\"/ || en_company_name.blank? || "#{en_company_name}" =~ /(-|ー)( |　)(.*)|(.*)( |　)(-|ー)/i
          csv << [row[0], nil]
          next
        end

        csv << [row[0], en_company_name]
        next
      end
      csv << [row[0], nil]
    end
    rescue => e
      p "#{row[0]}"
      p e
      csv << [row[0], nil]
      next
  end
end

File.open("result1.csv", "w") do |file|
  file.write(csv_file)
end