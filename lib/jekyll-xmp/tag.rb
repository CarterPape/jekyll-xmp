module Jekyll
    module XMP
        class Tag < Liquid::Tag
            PARAMETER_SYNTAX = %r!
                (           # key
                    [\w-]+  #
                )           #
                \s*=\s*
                (?:
                    "(                  # double-quoted literal value
                        [^"\\]*         #
                        (?:             #
                            \\.[^"\\]*  #
                        )*              #
                    )"                  #
                    |
                    '(                  # single-quoted literal value
                        [^'\\]*         #
                        (?:             #
                            \\.[^'\\]*  #
                        )*              #
                    )'                  #
                    |
                    (                   # variable value
                        [\w.-]+         #
                    )                   #
                )
            !x.freeze
            
            TAG_SYNTAX = %r!
                \A
                \s*
                (?:
                    #{PARAMETER_SYNTAX}
                    (?=
                        \s|\z
                    )
                    \s*
                )*
                \z
            !x.freeze
            
            TAG_NAME = "xmp"
            
            REQUIRED_PARAMETERS = [
                "file_path",
                "property_namespace",
                "property_name"
            ]
            
            def initialize(_, markup, _)
                super
                
                @markup = markup
                validate_markup()
            end
            
            def validate_markup
                unless TAG_SYNTAX.match?(@markup)
                    raise ArgumentError, <<~MSG
                        Invalid syntax for #{TAG_NAME} tag:
                        
                        #{@markup}
                        
                        Valid syntax:
                        
                        #{syntax_example}
                        
                    MSG
                end
            end
            
            def validate_parameters
                unless (REQUIRED_PARAMETERS.all? {|key| @parameters.key?(key)})
                    raise ArgumentError, <<~MSG
                        Invalid parameter list for #{TAG_NAME} tag:
                        
                        #{@parameters}
                        
                        Required parameters:
                        
                        #{REQUIRED_PARAMETERS}
                        
                    MSG
                end
            end
            
            def validate_file_path(path)
                unless File.file?(path)
                    raise IOError, "Could not locate file #{path}"
                end
            end
            
            def syntax_example
                "{% #{TAG_NAME} file='value' key=variable %}"
            end
            
            def parse_markup(context)
                @parameters = {}
                @markup.scan(PARAMETER_SYNTAX) do |key, d_quoted, s_quoted, variable|
                    value = (
                        if d_quoted
                            d_quoted.include?('\\"') ? d_quoted.gsub('\\"', '"') : d_quoted
                        elsif s_quoted
                            s_quoted.include?("\\'") ? s_quoted.gsub("\\'", "'") : s_quoted
                        elsif variable
                            context[variable]
                        end
                    )
                    
                    @parameters[key] = value
                end
            end
            
            def render(context)
                site = context.registers[:site]
                parse_markup(context)
                validate_parameters()
                
                image_path = site.in_source_dir(
                    @parameters["file_path"]
                )
                
                xml = nil
                
                if IO.read(image_path, 3, mode: "rb") == "\xFF\xD8\xFF".force_encoding("ASCII-8BIT")
                    xml = xml_from_jpeg(image_path)
                elsif IO.read(image_path, 8, mode: "rb") == "\x89PNG\x0d\x0a\x1a\x0a".force_encoding("ASCII-8BIT")
                    xml = xml_from_png(image_path)
                end
                
                require 'xmpr'
                XMPR.parse(xml)[
                    @parameters["property_namespace"],
                    @parameters["property_name"],
                ]
            end
            
            def xml_from_jpeg(file_path)
                xap = "http://ns.adobe.com/xap/1.0/\0".freeze
                file = File.open(file_path, 'rb')
                xml = nil
                
                begin
                    while !file.eof
                        case file.readbyte
                        when 0xFF
                            case file.readbyte
                            when 0xE1
                                size = file.read(2).unpack('H*').first.hex
                                next unless size > xap.length
                                
                                ns = file.read(xap.length)
                                if ns == xap
                                    xml = file.read(size - xap.length - 2)
                                    break
                                end
                            end
                        end
                    end
                ensure
                    file.close
                end
                
                return xml
            end
            
            def xml_from_png(file_path)
                file_chunks = nil
                xml = nil
                
                require 'chunky_png'
                File.open(file_path, 'rb') { |io|
                    file_chunks = ChunkyPNG::Datastream.from_io(io).chunks 
                }
                file_chunks.each { |chunk|
                    if chunk.type == "iTXt" and chunk.keyword == "XML:com.adobe.xmp"
                        xml = chunk.text
                    end
                }
                
                return xml
            end
        end
    end
end

Liquid::Template.register_tag(
    Jekyll::XMP::Tag::TAG_NAME,
    Jekyll::XMP::Tag,
)
