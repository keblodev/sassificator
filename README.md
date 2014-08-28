sassificator
============

css to sass converter

no conversion from sass back to css

and no tests. sorry. still gathering test_cases

Class params are specified in class's comments

Installation:
  
```
  gem install sassificator
```  

Requirements:

 * Requires a properly formatted man-read CSS code (with wihte_spaces, new lines , etc) on input, like:

```css
  selector-1 {
    rule1: value;
    ...
    ruleN: value;
  }

  selector-2 {
    rule1: value;
    ...
    ruleN: value;
  }
```

Features:

* Returns hierarchy Sass-formated object and Sass-formated string code
* Can alphabetise rules in output Sass-formated string code
* Can format images declarations to format asset-url('image.format') in Sass-formated string code
* Can download images, specified in css, to a specified deirectory
   ( default dir is ENV['HOME']/Desktop/sassificator_output/ )
* Can move colors declarations in to color sass_variables in Sass-formated string	


Usage:

```ruby
	sassificator_instance = Sassificator.new
	sass_hash_obj = sassificator_instance.get_sass_str_and_sass_obj css_input_text_code
```  

Output:

```ruby	
	:sass_obj 		# sass hierarchy object
	:sass_string	# sass_formated string
```