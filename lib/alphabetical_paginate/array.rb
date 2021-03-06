# coding: utf-8
# Warning! this is not the original alpha_paginate. Made changes to charasters support (croatian letters). Original can be found on:  https://github.com/lingz/alphabetical_paginate
class Array
  def alpha_paginate current_field, params = {enumerate:false, default_field: "a",
                                              paginate_all: false, numbers: true, include_all: true,
                                              others: true, pagination_class: "pagination-centered",
                                              js: true, support_language: :en, bootstrap3: false,
                                              slugged_link: false, slug_field: "slug", all_as_link: true, sort: true}
    params[:paginate_all] ||= false
    params[:support_language] ||= :en
    params[:language] = AlphabeticalPaginate::Language.new(params[:support_language])
    params[:include_all] = true if !params.has_key? :include_all
    params[:numbers] = true if !params.has_key? :numbers
    params[:others] = true if !params.has_key? :others
    params[:js] = true if !params.has_key? :js
    params[:default_field] ||= params[:include_all] ? "all" : params[:language].default_letter
    params[:pagination_class] ||= "pagination-centered"
    params[:slugged_link] ||= false
    params[:slugged_link] = params[:slugged_link] && defined?(Babosa)
    params[:slug_field] ||= "slug"
    params[:all_as_link] = true if !params.has_key? :all_as_link
    params[:sort] = true if !params.has_key? :sort

    output = []
    availableLetters = {}

    current_field ||= params[:default_field]
    current_field = current_field.mb_chars.downcase.to_s
    all = params[:include_all] && current_field == "all"

    self.each do |x|
      slug = eval("x.#{params[:slug_field]}") if params[:slugged_link]

      field_val = block_given? ? yield(x).to_s : x.id.to_s
      field_letter = field_val[0].to_s
      if params[:language].letters_range.include?(field_letter.upcase)
        availableLetters[field_letter] = true if !availableLetters.has_key? field_letter
        field = params[:slugged_link] ? slug : field_letter

        output << x if all || (current_field == field)
      elsif /[0-9]/.match(field_letter)
        if params[:enumerate]
          availableLetters[field_letter] = true if !availableLetters.has_key? field_letter
          output << x if all || (current_field =~ /[0-9]/ && field_letter == current_field)
        else
          availableLetters['0-9'] = true if !availableLetters.has_key? 'numbers'
          output << x if all || current_field == "0-9"
        end
      else
        availableLetters['*'] = true if !availableLetters.has_key? 'other'
        output << x if all || current_field == "*"
      end
    end

    params[:availableLetters] = availableLetters.collect{ |k,v| k.mb_chars.capitalize.to_s }
    params[:currentField] = current_field.mb_chars.capitalize.to_s
    params[:availableLetters] = params[:availableLetters][0..1] + params[:availableLetters][2..params[:availableLetters].length].sort.to_a

    output.sort! {|x, y| block_given? ? (yield(x).to_s <=> yield(y).to_s) : (x.id.to_s <=> y.id.to_s) } if params[:sort]
    return output, params
  end
end

