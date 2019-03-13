# Warning! this is not the original alpha_paginate. Made changes to charasters support (croatian letters). Original can be found on:  https://github.com/lingz/alphabetical_paginate
module AlphabeticalPaginate
  module ControllerHelpers
     LANGUAGE = ["0","1","2","3","4","5","6","7","8","9","A","B","C","Č","Ć","D","Đ","Dž","E","F","G","H","I","J","K","L","Lj","M","N","Nj","O","P","Q","R","S","Š","T","U","V","W","X","Y","Z","Ž","(",")", "{", "}", "[", "]", ',','.','?',"!","'",":",";", " "] # for now its quick fix. Should be manageble by some global state of application LANGUAGE

  def alpha_paginate current_field, items, params = {enumerate:false, default_field: "a",
                                              paginate_all: false, numbers: true,
                                              others: true, pagination_class: "pagination-centered",
                                              batch_size: 500, db_mode: false,
                                              db_field: "id", include_all: true,
                                              js: true, support_language: :en,
                                              bootstrap3: false, slugged_link: false,
                                              slug_field: "slug", all_as_link: true, sort: true}

    params = {}
    params[:default_field] ||= "a"
    params[:paginate_all] ||= false
    params[:support_language] ||= :en
    params[:language] = AlphabeticalPaginate::Language.new(params[:support_language])
    params[:include_all] = true if !params.has_key? :include_all
    params[:numbers] = true if !params.has_key? :numbers
    params[:others] = true if !params.has_key? :others
    params[:js] = true if !params.has_key? :js
    params[:pagination_class] ||= "pagination-centered"
    params[:batch_size] ||= 500
    params[:db_mode] ||= false
    params[:db_field] ||= "id"
    params[:slugged_link] ||= false
    params[:slugged_link] = params[:slugged_link] && defined?(Babosa)
    params[:slug_field] ||= "slug"
    params[:all_as_link] = true if !params.has_key? :all_as_link
    params[:sort] = true if !params.has_key? :sort


    output = {}

    if params[:include_all]
      current_field ||= 'all'
      all = current_field == "all"
    end

    current_field ||= params[:default_field]
    current_field = current_field.downcase
    all = params[:include_all] && current_field == "all"

    availableLetters = {}
    items.each do |key, value|
      field_letter = key.dig(:name)[0]
      if LANGUAGE.include?(field_letter.mb_chars.upcase.to_s)
        availableLetters[field_letter] = true if !availableLetters.has_key? field_letter
        field = params[:slugged_link] ? slug : field_letter

        output[key] =  value if all || (current_field == field.downcase)
      elsif /[0-9]/.match(field_letter)
        if params[:enumerate]
          availableLetters[field_letter] = true if !availableLetters.has_key? field_letter
          output[key] = value if all || (current_field =~ /[0-9]/ && field_letter == current_field)
        else
          availableLetters['0-9'] = true if !availableLetters.has_key? 'numbers'
          output[key] =  value if all || current_field == "0-9"
        end
      else
        availableLetters['*'] = true if !availableLetters.has_key? 'other'
        output[key] =  value if all || current_field == "*"
      end
      params[:availableLetters] = availableLetters.collect{ |k,v| k.mb_chars.capitalize.to_s }.uniq
    end
    params[:currentField] = current_field.mb_chars.capitalize.to_s

    return output.keys.sort { |e1, e2| sort_by_alphabeth(e1.dig(:name), e2.dig(:name)) }, output, params
  end

  private

    def sort_by_alphabeth(e1, e2)
      e1.chars.each_with_index do |char, index|
        if index >= e2.length
          return 1
        end
        if LANGUAGE.find_index(char.upcase) == LANGUAGE.find_index(e2[index].upcase)
          next
        elsif LANGUAGE.find_index(char.upcase) > LANGUAGE.find_index(e2[index].upcase)
          return 1
        elsif LANGUAGE.find_index(char.upcase) < LANGUAGE.find_index(e2[index].upcase)
          return -1
        else
          return nil
        end
      end
      return 1
    end
  end
end

