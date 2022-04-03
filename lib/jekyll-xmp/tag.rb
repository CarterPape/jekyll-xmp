module Jekyll
    module XMP
        class Tag < Liquid::Tag
            def initialize(tag_name, text, tokens)
                super
                @text = text
            end
            
            def render(context)
                "#{@text} #{Time.now}"
            end
        end
    end
end

Liquid::Template.register_tag('xmp', Jekyll::XMP::Tag)
