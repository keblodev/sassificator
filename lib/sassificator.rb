#TODO:
# - mediaquery inside of a mediaquery
# - images formating pattern setting
# - formatting is doen only for output sass_string, but not for sass_obj

class Sassificator
  attr_accessor :colors_to_vars
  ##
  #
  # @param [Boolean] alphabethize_output         true : Alphatehise the rules in output string
  # @param [Boolean] colors_to_vars              true : sets all color to sass variables to the top of output string
  # @param [Boolean] fromat_image_declarations   true : formats images declarations to asset-url (for now at least - TODO: will be unified for any format)
  # @param [Boolean] download_images             true : downloads images to specified @output_path
  # @param [String] output_path                  Output path must be specified if download_images is set to true
  #
  def initialize( param = {})
    @alphabethize_output =  (param[:alphabethize_output] != false) != false
    @colors_to_vars =  (param[:colors_to_vars] != false) != false
    @fromat_image_declarations = (param[:fromat_image_declarations] != false) != false
    @download_images =  (param[:download_images] != false) != false
    @output_path = param[:output_path] ? param[:output_path] : "#{ENV['HOME']}/Desktop/footer_output/"
  end

  ##
  #
  # Returns a hash containing sass_object and sass_formated string
  # REQUIRES A PROPERLY FROMATED INPUT CSS
  #
  # @param [String] css              A PROPERLY FROMATED INPUT CSS STRING | for now it's NOT working with media_query's inside of media_querys
  #
  def get_sass_str_and_sass_obj(input_css_str)
    selectors_hash = css_to_hash input_css_str      # 1. convert plain css to hash obj
    css_stack = objectize_css(selectors_hash)       # 2. convert recieved hash to sass obj with relatons
    sassed_css_string = sass_obj_to_str(css_stack)  # 3. get formatted string out sass_obj

    Hash[:sass_obj => css_stack, :sass_string => sassed_css_string]
  end

  private

  class CssNode
    attr_accessor :rule, :children, :parent, :uninitialized

    def initialize( param = {})
      @rule =  param[:rule] ? param[:rule] : ''
      @children = param[:children] ? param[:children] : {}
      @parent = param[:parent] ? param[:parent] : nil
      @parent = nil unless param[:parent]
      @uninitialized = param[:uninitialized] ? param[:uninitialized] : {}
    end
  end

  def remove_white_spaces_and_new_lines(line)
    line.gsub(/\n/,'').gsub(/\t/,'').gsub(/\s+(?=\})/,'').gsub(/(?<=\{)\s+/,'')
  end

  def css_to_hash (input_css)
    input_css = input_css.gsub(/::/,':')
    selectors_arr = remove_white_spaces_and_new_lines(input_css).gsub(/@media/,"\n@media").gsub(/(?<={{1}).+}(?=[\s\t\n]{0,}}{1})/,'').gsub(/(?<={{1}).+}(?=[\s\t\n]{0,}}{1})/,'').scan(/[^{^}]+(?=\{)/).map {|line| line.sub(/^\s+/,'').sub(/\s+$/,'')}
    rules_arr = remove_white_spaces_and_new_lines(input_css).gsub(/@media/,"\n@media").scan(/(((?<={{1}).+}(?=[\s\t\n]{0,}}{1})|(?<=\{)[^}]+\}{0,}[\\t\\n\s]{0,}(?=\}))|((?<=\{)[^}]+\}{0,}[\\t\\n\s]{0,}(?=\}))|(?<={{1}).+}(?=[\s\t\n]{0,}}{1}))/).map {|item| item.compact.uniq.join} #super-mega reg-exp that scans for normal rules as well as inlined media-query rule + make a single_string_items out of matched array groups
    return_hash = {}

    selectors_arr.each_with_index do |selector, index|
      unless return_hash[selector]
        return_hash[selector] = rules_arr[index.to_i]
      else
        return_hash[selector] = return_hash[selector] + ' ' + rules_arr[index.to_i]
      end
    end

    return_hash.each do |key,val|
      unless val.scan(/[^{^}]+(?=\{)/).size.zero?
        return_hash[key] = css_to_hash val
      end
    end

    return_hash
  end

  def objectize_css (uninitialized_childrens_hash, parent_node = nil)

    childrens_stack = {}

    uninitialized_childrens_hash.each { |selector,rule|

      #TODO: optimize pattern mathcing = thei are both matching same string
      match = /^[&.#\"\'\[\]=a-zA-Z-_0-9]{1,}(?=\s(?=[^,]{0,}$))/.match(selector).to_s #checks for childrens in selector

      sub_pat = /^[\.#]{0,1}[a-zA-Z-_0-9]{1,}(?=(\.|:|\[|#))/.match(selector).to_s   #deals with pseudo elements
      #TODO : optimize this
      unless sub_pat.empty?
        unless selector.match(/,/)

          match = sub_pat
          selector = selector.sub( Regexp.new('^'+match) ,match+' &')
        end
      end

      unless match.empty?
        unless node = childrens_stack[match]
          node = CssNode.new
          childrens_stack[match] = node
        end
        node.uninitialized[selector.sub( Regexp.new('^'+match+' ') ,'')] =  rule
        node.parent = parent_node
      else
        if node = childrens_stack[selector]
          node.rule = node.rule + "\n\t" + rule.gsub(/;\s/,";\n\t")
        else
          node = CssNode.new
          if rule.is_a?(Hash)
            node.children = objectize_css( rule, node )
          else
            node.rule = "\n\t"+rule.gsub(/;\s/,";\n\t")
          end
          childrens_stack[selector] = node
        end
        node.rule = node.rule.split(';').sort().join(';') + ';' if @alphabethize_output && !node.rule.empty? #alphabetize
        node.parent = parent_node
      end
    }

    childrens_stack.each { |node_selector,node|
      unless childrens_stack[node_selector].uninitialized.empty?
        childrens_stack[node_selector].children =  objectize_css( childrens_stack[node_selector].uninitialized, node )
        childrens_stack[node_selector].uninitialized = []
      end
    }

    childrens_stack
  end

  def sass_obj_to_str (css_stack)
    sassed_str = format_sass sass_stack_to_s(css_stack)

    sassed_str
  end

  def sass_stack_to_s (css_stack)
    str = ''
    css_stack.each { |node_key,node|
      unless node.children.empty?
        chldrn = node.children
        children_stack = sass_stack_to_s(chldrn)
      end
      str = str +"\n"+ node_key + " {\t" + ( node.rule ? node.rule  : '') + ( children_stack ? children_stack.gsub(/^/,"\t") : '' ) +"\n\t}"
    }

    str
  end

  def format_sass (sassed_str)
    formated_sass_with_images = @fromat_image_declarations ? format_images(sassed_str) : sassed_str
    formated_sass_with_color = @colors_to_vars ? format_color(formated_sass_with_images) : sassed_str

    formated_sass_with_color
  end

  def format_images (sassed_str)

    require 'net/http'

    formated_rule = sassed_str
    sassed_str.scan(/(url\((((http[s]{0,1}:\/\/)([a-z0-9].+\.[a-z]+).+)(\/.+)))\)/).each do |match|

      formated_rule = formated_rule.sub(Regexp.new(match[0].gsub(/\(/,'\(').gsub(match[5],'')),'asset-url(\'#{$brand}')
      .sub( Regexp.new(match[5]),match[5]+'\',image')

      Net::HTTP.start(match[4]) do |http|
        resp = http.get(match[1])

        #TODO: optimise this - connect to global path
        path = @output_path
        Dir.mkdir(path) unless Dir.exist?(path)
        open(path+match[5], 'wb') do |file|
          begin
            file.write(resp.body)
          ensure
            file.close()
          end
        end
      end
    end

    formated_rule
  end

  def format_color(sassed_str)
    #TODO: resolve the match for colors in format #sdsd
    formated_rule = sassed_str
    color_hash = {}
    sassed_str.scan(/rgba\([0-9\,\s\.]+\)|rgb\([0-9\,\s\.]+\)/).each do|m|

      unless color_hash[m]
        color_hash[m] = '$brand_color_'+color_hash.size.to_s
        formated_rule = formated_rule.gsub( Regexp.new(m.gsub(/\(/,'\(').gsub(/\)/,'\)').gsub(/\./,'\.')), color_hash[m] )
      end
    end

    color_hash.invert.to_a.reverse_each {|m|
      formated_rule = m.join(":")+"\n" + formated_rule
    }

    formated_rule
  end

  def format_mixin
    #TODO: combine similar rules blocks in mixins.. in some way..?
  end
end