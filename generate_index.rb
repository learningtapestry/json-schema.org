

def schema_links
  links = []
  Dir.foreach('./schemas') do |fname|
    next if fname.start_with? '.'
    links << <<-HTML

      <li>
        <a href="/json-schema.org/schemas/#{fname}">#{ fname.gsub('.json', '') }</a>
      </li>
    HTML
  end
  links.join
end

index_html = <<-HTML
<h1>JSON-schema definitions for Schema.org entities</h1>

<p>
  You can request the schema in json format.
  </br>

  The schema urls follow the pattern:
   https://learningtapestry.github.io/json-schema.org/schemas/[ENTITY_NAME].json
   <br/>

   See below all currently valid urls:
   <br/>

  <ul>
    #{schema_links}
  </ul>
</p>
HTML

file = File.open('./index.html', 'w')
file.write index_html
file.close
