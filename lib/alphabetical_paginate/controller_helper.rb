# Warning! this is not the original alpha_paginate. Made changes to charasters support (croatian letters). Original can be found on:  https://github.com/lingz/alphabetical_paginate
module AlphabeticalPaginate
  module ControllerHelpers
    def self.included(base)
      base.extend(self)
    end

    def alpha_paginate current_field, params = {enumerate:false, default_field: "a",
                                                paginate_all: false, numbers: true,
                                                others: true, pagination_class: "pagination-centered",
                                                batch_size: 500, db_mode: false,
                                                db_field: "id", include_all: true,
                                                js: true, support_language: :en,
                                                bootstrap3: false, slugged_link: false,
                                                slug_field: "slug", all_as_link: true, sort: true}
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


      output = []

      if params[:db_mode]
        letters = nil
        if !params[:paginate_all]
          letters = filter_by_cardinality( find_available_letters(params[:db_field]) )
          set_default_field letters, params
        end
        params[:availableLetters] = letters.nil? ? [] : letters
      end

      if params[:include_all]
        current_field ||= 'all'
        all = current_field == "all"
      end

      current_field ||= params[:default_field]
      current_field = current_field.downcase
      all = params[:include_all] && current_field == "all"

      if params[:db_mode]
        if !ActiveRecord::Base.connection.adapter_name.downcase.include? "mysql"
          raise "You need a mysql database to use db_mode with alphabetical_paginate"
        end

        if all
          output = self
        else

          # In this case we can speed up the search taking advantage of the indices
          can_go_quicker = (current_field =~ params[:language].letters_regexp) || (current_field =~ /[0-9]/ && params[:enumerate])


          # Use LIKE the most as you can to take advantage of indeces on the field when available
          # REGEXP runs always a full scan of the table!
          # For more information about LIKE and indeces have a look at
          # http://myitforum.com/cs2/blogs/jnelson/archive/2007/11/16/108354.aspx

          # Also use some sanitization from ActiveRecord for the current field passed
          if can_go_quicker
            output = self.where("LOWER(%s) LIKE ?" % params[:db_field], current_field+'%')
          else
            regexp_to_check = current_field =~ /[0-9]/ ? '^[0-9]' : '^[^a-z0-9]'
            output = self.where("LOWER(%s) REGEXP '%s.*'" % [params[:db_field], regexp_to_check])
          end
        end
      else
        availableLetters = {}
        self.each do |x|
          slug = eval("x.#{params[:slug_field]}") if params[:slugged_link]

          field_val = block_given? ? yield(x).to_s : x.id.to_s
          field_letter = field_val[0].to_s
          field = params[:slugged_link] ? slug : field_letter
          if params[:language].letters_range.include?(field_letter.mb_chars.upcase.to_s)
            availableLetters[field_letter] = true if !availableLetters.has_key? field_letter
            field = params[:slugged_link] ? slug : field_letter

            output << x if all || (current_field == field.downcase)
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

        params[:availableLetters] = availableLetters.collect{ |k,v| k.mb_chars.capitalize.to_s }.uniq
      end
      params[:currentField] = current_field.mb_chars.capitalize.to_s

      return ((params[:db_mode] && params[:db_field]) ? output.order("#{params[:db_field]} ASC") : output), params
    end

    private

    def set_default_field(letters, params)
      if letters.any?
        params[:default_field] = letters.first
      elsif params[:include_all]
        params[:default_field] = 'all'
      else
        params[:default_field] = params[:language].default_letter
      end
    end

    def filter_by_cardinality(letters)
      letters.collect do |letter, count|
        if count > 0
          letter = letter.mb_chars.capitalize.to_s
        else
          nil
        end
        # repass again to filter duplicates *
      end.uniq
    end

    def find_available_letters(db_field)
      # safe the field (look for the ActiveRecord valid attributes)
      # but allow explict table name prefixes in order to avoid 'field list is ambiguous' errors
      if db_field.nil? || !self.attribute_names.include?(db_field.to_s.split('.').last)
        db_field = 'id'
      end
      criteria = "substr( %s, 1 , 1)" % db_field
      self.select(criteria).group(criteria).order(criteria).count(db_field)
    end
  end
end
