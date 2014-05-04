sassificator
============

css to sass converter

no convertion from sass back to css

and no tests. sorry.

Class params are specified in class's comments

Features:
* Returns hierarchy Sass-formated object and Sass-formated string
* Can alphabethise rules inside output Sass-formated string
* Can fromat images declarations to format asset-url(image.format, image) in Sass-formated string
* Can download images to a specified deirectory
   ( default dir is ENV['HOME']/Desktop/sassificator_output/ )
* Can move colors declarations in to color variables in Sass-formated string	


Usage:

	sassificator_instance = Sassificator.new
	sass_hash_obj = sassificator_instance.get_sass_str_and_sass_obj css_input_text_code

Output
	
	:sass_obj 		- sass hierarchy object
	:sass_string	- sass_formated string
